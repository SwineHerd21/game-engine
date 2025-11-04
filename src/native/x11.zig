const std = @import("std");

const Window = @import("../Window.zig");
const events = @import("../events.zig");
const EngineError = @import("../lib.zig").EngineError;

const log = std.log.scoped(.engine);

// TODO: replace cImport with extern fns?
pub const c = @cImport({
    @cInclude("X11/X.h");
    @cInclude("X11/Xlib.h");

    @cInclude("GL/gl.h");
    @cInclude("GL/glx.h");
    @cInclude("GL/glu.h");
});

pub const Context = struct {
    display: *c.Display,
    window: c.Window,
    glx: c.GLXContext,
    event: c.XEvent,
    /// Handles closing the window with 'x' button
    wm_delete_window: c.Atom,
};

// TODO: Error handling

// ========== WINDOWING ==========

pub inline fn createWindow(width: u32, height: u32, title: []const u8) EngineError!Context {
    const display = if (c.XOpenDisplay(null)) |d| d else return EngineError.InitFailure;
    const root = c.DefaultRootWindow(display);

    // OpenGL attributes
    var gl_atts = [_]c_int{
        c.GLX_RGBA,
        c.GLX_DEPTH_SIZE, 24,
        c.GLX_DOUBLEBUFFER,
        c.None
    };
    const vi: *c.XVisualInfo = if (c.glXChooseVisual(display, 0, @ptrCast(&gl_atts))) |v| v else return EngineError.InitFailure;
    const cmap = c.XCreateColormap(display, root, vi.visual, c.AllocNone);

    var window_atts: c.XSetWindowAttributes = undefined;
    window_atts.colormap = cmap;
    window_atts.event_mask = c.KeymapStateMask | c.KeyPressMask | c.KeyReleaseMask | c.ButtonPressMask | c.ButtonReleaseMask | c.PointerMotionMask | c.EnterWindowMask | c.LeaveWindowMask | c.FocusChangeMask | c.StructureNotifyMask | c.ExposureMask;

    const window = c.XCreateWindow(display, root, 0, 0, width, height, 0, vi.depth, c.InputOutput, vi.visual, c.CWColormap | c.CWEventMask, &window_atts);

    // The later functions return values don't mean anything
    // Set window name
    _ = c.XStoreName(display, window, @ptrCast(title));

    _ = c.XClearWindow(display, window);
    _ = c.XMapRaised(display, window);

    // window closing detection
    const wm_delete_window = c.XInternAtom(display, "WM_DELETE_WINDOW", 0);
    // should the result be checked for 0? idk
    _ = c.XSetWMProtocols(display, window, @constCast(&wm_delete_window), 1);

    log.info("Running on Linux with X11", .{});

    // OpenGL context
    const glx = c.glXCreateContext(display, vi, null, c.GL_TRUE);
    _ = c.glXMakeCurrent(display, window, glx);

    c.glClearColor(0, 0, 0, 1);

    return .{
        // TODO: check for null pointers
        .display = display,
        .window = window,
        .glx = glx,
        .event = undefined,
        .wm_delete_window = wm_delete_window,
    };
}

pub inline fn closeWindow(ctx: Context) void {
    _ = c.glXMakeCurrent(ctx.display, c.None, null);
    _ = c.glXDestroyContext(ctx.display, ctx.glx);
    _ = c.XUnmapWindow(ctx.display, ctx.window);
    _ = c.XDestroyWindow(ctx.display, ctx.window);
    _ = c.XCloseDisplay(ctx.display);
}

pub inline fn areEventsPending(ctx: Context) bool {
    return c.XPending(ctx.display) != 0;
}

pub inline fn consumeEvent(window: *Window) ?events.Event {
    _ = c.XNextEvent(window.inner.display, &window.inner.event);
    switch (window.inner.event.type) {
        c.KeymapNotify => _ = c.XRefreshKeyboardMapping(&window.inner.event.xmapping),
        c.KeyPress => {
            const ev = window.inner.event.xkey;

            return events.Event{
                .key_press = .{
                    .keycode = @truncate(ev.keycode),
                    .modifiers = .{
                        .shift = ev.state & (1<<0) == 1,
                        .control = ev.state & (1<<2) == 1<<2,
                        .alt = ev.state & (1<<3) == 1<<3,
                        .super = ev.state & (1<<6) == 1<<6,
                    },
                },
            };
        },
        c.KeyRelease => {
            const ev = window.inner.event.xkey;

            return events.Event{
                .key_release = .{
                    .keycode = @truncate(ev.keycode),
                    .modifiers = .{
                        .shift = ev.state & (1<<0) == 1,
                        .control = ev.state & (1<<2) == 1<<2,
                        .alt = ev.state & (1<<3) == 1<<3,
                        .super = ev.state & (1<<6) == 1<<6,
                    },
                },
            };
        },
        c.ButtonPress => {
            const ev = window.inner.event.xbutton;

            return events.Event{
                .pointer_button_press = .{
                    .button = @truncate(ev.button),
                },
            };
        },
        c.ButtonRelease => {
            const ev = window.inner.event.xbutton;

            return events.Event{
                .pointer_button_release = .{
                    .button = @truncate(ev.button),
                },
            };
        },
        c.MotionNotify => {
            const ev = window.inner.event.xmotion;

            return events.Event{
                .pointer_motion = .{ev.x, ev.y},
            };
        },
        c.EnterNotify => {
            return events.Event{
                .pointer_enter = {},
            };
        },
        c.LeaveNotify => {
            return events.Event{
                .pointer_exit = {},
            };
        },
        c.FocusIn => {
            return events.Event{
                .focus_gained = {},
            };
        },
        c.FocusOut => {
            return events.Event{
                .focus_lost = {},
            };
        },
        c.ConfigureNotify => {
            const ev = window.inner.event.xconfigure;

            if (ev.width != window.width or ev.height != window.height) {
                return events.Event{
                    .window_resize = .{
                        .width = @intCast(ev.width),
                        .height = @intCast(ev.height)},
                };
            }
        },
        c.DestroyNotify => {
            return events.Event{
                .window_close = {},
            };
        },
        c.Expose => {
            return events.Event{
                .window_expose = {},
            };
        },
        // Weird thing without which the app crashes when the window manager closes the window
        c.ClientMessage => if (@as(c.Atom, @intCast(window.inner.event.xclient.data.l[0])) == window.inner.wm_delete_window) {
            return events.Event{
                .window_close = {},
            };
        },
        else => {},
    }
    return null;
}

// ========== OTHER ==========

pub inline fn swapBuffers(ctx: Context) void {
    _ = c.glXSwapBuffers(ctx.display, ctx.window);
}

pub const getProcAddress = c.glXGetProcAddress;
