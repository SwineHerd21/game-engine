const Window = @import("../Window.zig");
const events = @import("../events.zig");

// TODO: replace cImport with extern fns
pub const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("stdlib.h");
    @cInclude("X11/X.h");
    @cInclude("X11/Xlib.h");
});

pub const Context = struct {
    display: *c.Display,
    screen: *c.Screen,
    window: c.Window,
    event: c.XEvent,
    /// Handles closing the window with 'x' button
    wm_delete_window: c.Atom,
};

// TODO: Error handling probably?

pub inline fn createWindow(width: u32, height: u32, title: []const u8) Context {
    const display = c.XOpenDisplay(null);
    const screen = c.DefaultScreenOfDisplay(display);
    const window = c.XCreateSimpleWindow(display, c.RootWindowOfScreen(screen), 0, 0, width, height, 0, screen.white_pixel, screen.black_pixel);

    _ = c.XStoreName(display, window, @ptrCast(title));

    _ = c.XClearWindow(display, window);
    _ = c.XMapRaised(display, window);

    _ = c.XSelectInput(display, window, c.KeymapStateMask | c.KeyPressMask | c.KeyReleaseMask | c.ButtonPressMask | c.ButtonReleaseMask | c.PointerMotionMask | c.EnterWindowMask | c.LeaveWindowMask | c.FocusChangeMask | c.StructureNotifyMask);

    const wm_delete_window = c.XInternAtom(display, "WM_DELETE_WINDOW", 0);
    _ = c.XSetWMProtocols(display, window, @constCast(&wm_delete_window), 1);

    return .{
        // TODO: check for null pointers
        .display = display.?,
        .screen = @ptrCast(screen),
        .window = window,
        .event = undefined,
        .wm_delete_window = wm_delete_window,
    };
}

pub inline fn closeWindow(ctx: Context) void {
    _ = c.XUnmapWindow(ctx.display, ctx.window);
    _ = c.XDestroyWindow(ctx.display, ctx.window);
    _ = c.XCloseDisplay(ctx.display);
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
                        .control = ev.state & (1<<2) == 1,
                        .alt = ev.state & (1<<3) == 1,
                        .super = ev.state & (1<<6) == 1,
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
                        .control = ev.state & (1<<2) == 1,
                        .alt = ev.state & (1<<3) == 1,
                        .super = ev.state & (1<<6) == 1,
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
        // Weird thing needed for the 'x' button on the window to be usable
        c.ClientMessage => if (@as(c.Atom, @intCast(window.inner.event.xclient.data.l[0])) == window.inner.wm_delete_window) {
            return events.Event{
                .window_close = {},
            };
        },
        else => {},
    }
    return null;
}

