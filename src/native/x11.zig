const std = @import("std");

const math = @import("../math/math.zig");
const Window = @import("../Window.zig");
const Input = @import("../Input.zig");
const events = @import("../events.zig");
const EngineError = @import("../lib.zig").EngineError;

const log = std.log.scoped(.engine);

// TODO: replace cImport with extern fns?
pub const c = @cImport({
    @cInclude("X11/X.h");
    @cInclude("X11/Xlib.h");
    @cInclude("X11/XKBlib.h");

    @cInclude("GL/glx.h");
});

pub const Context = struct {
    display: *c.Display,
    window: c.Window,
    width: u32,
    height: u32,
    glx: c.GLXContext,
    event: c.XEvent,
    /// Handles closing the window with `x` button
    wm_delete_window: c.Atom,
    /// Mapping of hardware keycodes to `Key`s
    keycodes: [256]Input.Key,
    /// If true supresses key release events
    repeated_keypress: bool,
};

// ========== WINDOWING ==========

pub inline fn createWindow(width: u32, height: u32, title: []const u8) EngineError!Context {
    const display = if (c.XOpenDisplay(null)) |d| d else return EngineError.InitFailure;
    const root = c.DefaultRootWindow(display);

    // XKB check
    if (c.XkbQueryExtension(display, null, null, null, null, null) == 0) {
        log.err("Could not detect XKB", .{});
        return EngineError.InitFailure;
    }

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
    window_atts.event_mask = c.KeyPressMask | c.KeyReleaseMask | c.ButtonPressMask | c.ButtonReleaseMask | c.PointerMotionMask | c.EnterWindowMask | c.LeaveWindowMask | c.FocusChangeMask | c.StructureNotifyMask | c.ExposureMask;

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

    log.info("Running on Linux with X11 {}", .{c.XProtocolVersion(display)});

    // OpenGL context
    const glx = c.glXCreateContext(display, vi, null, c.GL_TRUE);
    _ = c.glXMakeCurrent(display, window, glx);

    return .{
        // TODO: check for null pointers
        .display = display,
        .window = window,
        .width = width,
        .height = height,
        .glx = glx,
        .event = undefined,
        .wm_delete_window = wm_delete_window,
        .keycodes = setupKeycodes(display),
        .repeated_keypress = false,
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

pub inline fn consumeEvent(ctx: *Context, input: Input) ?events.Event {
    _ = c.XNextEvent(ctx.display, &ctx.event);
    switch (ctx.event.type) {
        c.KeyPress => {
            if (c.XFilterEvent(&ctx.event, c.None) != 0) return null;

            const ev = ctx.event.xkey;

            const repeated = ctx.repeated_keypress;
            // If this was true then reset it to allow the actual release to go through
            ctx.repeated_keypress = false;

            return events.Event{
                .key_press = .{
                    .key = ctx.keycodes[ev.keycode],
                    .modifiers = translateKeyModifiers(ev.state),
                    .action = if (repeated) .Repeat else .Press,
                },
            };
        },
        c.KeyRelease => {
            const ev = ctx.event.xkey;

            // Check if this keystroke is repeated
            var next: c.XEvent = undefined;
            if (c.XPending(ctx.display) != 0) {
                _=c.XPeekEvent(ctx.display, &next);
                // For repeated key presses X11 will send a KeyPress and KeyRelease simultaneously
                if (next.type == c.KeyPress and next.xkey.time == ev.time and next.xkey.keycode == ev.keycode) {
                    ctx.repeated_keypress = true;
                    return null;
                }
            }

            return events.Event{
                .key_release = .{
                    .key = ctx.keycodes[ev.keycode],
                    .modifiers = translateKeyModifiers(ev.state),
                    .action = .Release,
                },
            };
        },
        c.ButtonPress => {
            const ev = ctx.event.xbutton;

            return events.Event{
                .mouse_button_press = .{
                    .button = @enumFromInt(ev.button),
                    .modifiers = translateKeyModifiers(ev.state),
                    .action = .Press,
                },
            };
        },
        c.ButtonRelease => {
            const ev = ctx.event.xbutton;

            return events.Event{
                .mouse_button_release = .{
                    .button = @enumFromInt(ev.button),
                    .modifiers = translateKeyModifiers(ev.state),
                    .action = .Release,
                },
            };
        },
        c.MotionNotify => {
            const ev = ctx.event.xmotion;

            const position = math.Vec2i.new(ev.x, ev.y);
            return events.Event{
                .pointer_motion = .{
                    .position = position,
                    .delta = position.sub(input.pointer_position),
                },
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
            const ev = ctx.event.xconfigure;

            if (ev.width != ctx.width or ev.height != ctx.height) {
                ctx.width = @intCast(ev.width);
                ctx.height = @intCast(ev.height);

                return events.Event{
                    .window_resize = .{
                        .width = @intCast(ev.width),
                        .height = @intCast(ev.height),
                    },
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
                .window_redraw = {},
            };
        },
        // Weird thing without which the app crashes when the window manager closes the window
        c.ClientMessage => if (@as(c.Atom, @intCast(ctx.event.xclient.data.l[0])) == ctx.wm_delete_window) {
            return events.Event{
                .window_close = {},
            };
        },
        else => {},
    }
    return null;
}

// Borrowed from https://github.com/glfw/glfw/blob/master/src/x11_init.c
fn setupKeycodes(display: *c.Display) [256]Input.Key {
    const keys = struct {
        key: Input.Key,
        name: []const u8,
    };
    const keymap = [_]keys{
        .{ .key = .Backquote, .name = "TLDE" },
        .{ .key = .@"1", .name = "AE01" },
        .{ .key = .@"2", .name = "AE02" },
        .{ .key = .@"3", .name = "AE03" },
        .{ .key = .@"4", .name = "AE04" },
        .{ .key = .@"5", .name = "AE05" },
        .{ .key = .@"6", .name = "AE06" },
        .{ .key = .@"7", .name = "AE07" },
        .{ .key = .@"8", .name = "AE08" },
        .{ .key = .@"9", .name = "AE09" },
        .{ .key = .@"0", .name = "AE10" },
        .{ .key = .Minus, .name = "AE11" },
        .{ .key = .Equal, .name = "AE12" },
        .{ .key = .Q, .name = "AD01" },
        .{ .key = .W, .name = "AD02" },
        .{ .key = .E, .name = "AD03" },
        .{ .key = .R, .name = "AD04" },
        .{ .key = .T, .name = "AD05" },
        .{ .key = .Y, .name = "AD06" },
        .{ .key = .U, .name = "AD07" },
        .{ .key = .I, .name = "AD08" },
        .{ .key = .O, .name = "AD09" },
        .{ .key = .P, .name = "AD10" },
        .{ .key = .BracketLeft, .name = "AD11" },
        .{ .key = .BracketRight, .name = "AD12" },
        .{ .key = .A, .name = "AC01" },
        .{ .key = .S, .name = "AC02" },
        .{ .key = .D, .name = "AC03" },
        .{ .key = .F, .name = "AC04" },
        .{ .key = .G, .name = "AC05" },
        .{ .key = .H, .name = "AC06" },
        .{ .key = .J, .name = "AC07" },
        .{ .key = .K, .name = "AC08" },
        .{ .key = .L, .name = "AC09" },
        .{ .key = .Semicolon, .name = "AC10" },
        .{ .key = .Quote, .name = "AC11" },
        .{ .key = .Z, .name = "AB01" },
        .{ .key = .X, .name = "AB02" },
        .{ .key = .C, .name = "AB03" },
        .{ .key = .V, .name = "AB04" },
        .{ .key = .B, .name = "AB05" },
        .{ .key = .N, .name = "AB06" },
        .{ .key = .M, .name = "AB07" },
        .{ .key = .Comma, .name = "AB08" },
        .{ .key = .Period, .name = "AB09" },
        .{ .key = .Slash, .name = "AB10" },
        .{ .key = .Backslash, .name = "BKSL" },
        .{ .key = .Space, .name = "SPCE" },
        .{ .key = .Escape, .name = "ESC" },
        .{ .key = .Enter, .name = "RTRN" },
        .{ .key = .Tab, .name = "TAB" },
        .{ .key = .Backspace, .name = "BKSP" },
        .{ .key = .Insert, .name = "INS" },
        .{ .key = .Delete, .name = "DELE" },
        .{ .key = .ArrowRight, .name = "RGHT" },
        .{ .key = .ArrowLeft, .name = "LEFT" },
        .{ .key = .ArrowDown, .name = "DOWN" },
        .{ .key = .ArrowUp, .name = "UP" },
        .{ .key = .PageUp, .name = "PGUP" },
        .{ .key = .PageDown, .name = "PGDN" },
        .{ .key = .Home, .name = "HOME" },
        .{ .key = .End, .name = "END" },
        .{ .key = .CapsLock, .name = "CAPS" },
        .{ .key = .ScrollLock, .name = "SCLK" },
        .{ .key = .NumLock, .name = "NMLK" },
        .{ .key = .PrintScreen, .name = "PRSC" },
        .{ .key = .Pause, .name = "PAUS" },
        .{ .key = .F1, .name = "FK01" },
        .{ .key = .F2, .name = "FK02" },
        .{ .key = .F3, .name = "FK03" },
        .{ .key = .F4, .name = "FK04" },
        .{ .key = .F5, .name = "FK05" },
        .{ .key = .F6, .name = "FK06" },
        .{ .key = .F7, .name = "FK07" },
        .{ .key = .F8, .name = "FK08" },
        .{ .key = .F9, .name = "FK09" },
        .{ .key = .F10, .name = "FK10" },
        .{ .key = .F11, .name = "FK11" },
        .{ .key = .F12, .name = "FK12" },
        .{ .key = .F13, .name = "FK13" },
        .{ .key = .F14, .name = "FK14" },
        .{ .key = .F15, .name = "FK15" },
        .{ .key = .F16, .name = "FK16" },
        .{ .key = .F17, .name = "FK17" },
        .{ .key = .F18, .name = "FK18" },
        .{ .key = .F19, .name = "FK19" },
        .{ .key = .F20, .name = "FK20" },
        .{ .key = .F21, .name = "FK21" },
        .{ .key = .F22, .name = "FK22" },
        .{ .key = .F23, .name = "FK23" },
        .{ .key = .F24, .name = "FK24" },
        .{ .key = .Numpad_0, .name = "KP0" },
        .{ .key = .Numpad_1, .name = "KP1" },
        .{ .key = .Numpad_2, .name = "KP2" },
        .{ .key = .Numpad_3, .name = "KP3" },
        .{ .key = .Numpad_4, .name = "KP4" },
        .{ .key = .Numpad_5, .name = "KP5" },
        .{ .key = .Numpad_6, .name = "KP6" },
        .{ .key = .Numpad_7, .name = "KP7" },
        .{ .key = .Numpad_8, .name = "KP8" },
        .{ .key = .Numpad_9, .name = "KP9" },
        .{ .key = .Numpad_Decimal, .name = "KPDL" },
        .{ .key = .Numpad_Divide, .name = "KPDV" },
        .{ .key = .Numpad_Multiply, .name = "KPMU" },
        .{ .key = .Numpad_Minus, .name = "KPSU" },
        .{ .key = .Numpad_Plus, .name = "KPAD" },
        .{ .key = .Numpad_Enter, .name = "KPEN" },
        .{ .key = .ShiftLeft, .name = "LFSH" },
        .{ .key = .ControlLeft, .name = "LCTL" },
        .{ .key = .AltLeft, .name = "LALT" },
        .{ .key = .SuperLeft, .name = "LWIN" },
        .{ .key = .ShiftRight, .name = "RTSH" },
        .{ .key = .ControlRight, .name = "RCTL" },
        .{ .key = .AltRight, .name = "RALT" },
        .{ .key = .AltRight, .name = "LVL3" },
        .{ .key = .AltRight, .name = "MDSW" },
        .{ .key = .SuperRight, .name = "RWIN" },
        .{ .key = .Menu, .name = "MENU" },
    };

    var keycodes: [256]Input.Key = .{.Unknown}**256;

    const desc: *c.struct__XkbDesc = @ptrCast(c.XkbGetMap(display, 0, c.XkbUseCoreKbd));
    defer c.XkbFreeKeyboard(desc, 0, c.True);
    _=c.XkbGetNames(display, c.XkbKeyNamesMask | c.XkbKeyAliasesMask, desc);
    defer c.XkbFreeNames(desc, c.XkbKeyNamesMask | c.XkbKeyAliasesMask, c.True);

    for (@intCast(desc.min_key_code)..@intCast(desc.max_key_code)) |scancode| {
        var key: Input.Key = .Unknown;

        for (keymap) |map| {
            if (std.mem.eql(u8, map.name, desc.names.*.keys[scancode].name[0..(map.name.len)])) {
                key = map.key;
                break;
            }
        }

        if (key == .Unknown) {
            // Alias fallback
            for (0..@intCast(desc.names.*.num_key_aliases)) |i| outer: {
                // Alias doesn't match the key
                if (!std.mem.eql(u8, desc.names.*.key_aliases[i].real[0..4], desc.names.*.keys[scancode].name[0..4])) continue;

                for (keymap) |map| {
                    if (std.mem.eql(u8, map.name, desc.names.*.key_aliases[i].alias[0..(map.name.len)])) {
                        key = map.key;
                        break :outer;
                    }
                }
            }
        }

        keycodes[scancode] = key;
    }

    return keycodes;
}

inline fn translateKeyModifiers(state: c_uint) Input.ModifierKeys {
    return .{
        .shift = state & c.ShiftMask != 0,
        .control = state & c.ControlMask != 0,
        .alt = state & c.Mod1Mask != 0,
        .super = state & c.Mod4Mask != 0,
        .caps_lock = state & c.LockMask != 0,
        .num_lock = state & c.Mod2Mask != 0,
    };
}

// ========== OTHER ==========

pub inline fn swapBuffers(ctx: Context) void {
    _ = c.glXSwapBuffers(ctx.display, ctx.window);
}

pub const getProcAddress = c.glXGetProcAddress;
