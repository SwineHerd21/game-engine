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
    @cInclude("X11/Xatom.h");
    @cInclude("X11/XKBlib.h");

    @cInclude("GL/glx.h");
});

pub const Context = struct {
    display: *c.Display,
    root: c.XID,
    window: c.Window,
    width: u32,
    height: u32,
    glx: c.GLXContext,
    event: c.XEvent,
    /// Mapping of hardware keycodes to `Key`s
    keycodes: [256]Input.Key,
    /// If true supresses key release events
    repeated_keypress: bool,
    atoms: struct {
        /// Used to check for window manager messages
        wm_protocols: c.Atom,
        /// Handles closing the window with `x` button
        wm_delete_window: c.Atom,
        /// Window manager checks if app is still working
        net_wm_ping: c.Atom,
        net_wm_state: c.Atom,
        net_wm_state_fullscreen: c.Atom,
        net_wm_state_maximized_horz: c.Atom,
        net_wm_state_maximized_vert: c.Atom,
        net_wm_bypass_compositor: c.Atom,
        /// Used for controlling window decoration
        motif_wm_hints: c.Atom,
    },
};

// ========== MAIN ==========

pub inline fn createWindow(width: u32, height: u32, title: []const u8) EngineError!Context {
    const display = if (c.XOpenDisplay(null)) |d| d else return error.InitFailure;

    // XKB check
    if (c.XkbQueryExtension(display, null, null, null, null, null) == 0) {
        log.err("Could not detect XKB", .{});
        return error.InitFailure;
    }
    // GLX check
    {
        var glx_major: c_int = undefined;
        var glx_minor: c_int = undefined;
        if (c.glXQueryVersion(display, &glx_major, &glx_minor) == 0) {
            log.err("Could not get GLX version", .{});
            return error.InitFailure;
        }
        if (glx_major < 1 or (glx_major == 1 and glx_minor < 3)) {
            log.err("Invalid GLX version {}.{}, require 1.3", .{glx_major, glx_minor});
            return error.InitFailure;
        }
    }

    const root = c.DefaultRootWindow(display);

    // OpenGL attributes
    var gl_atts = [_]c_int{
        c.GLX_RGBA,
        c.GLX_RED_SIZE, 8,
        c.GLX_GREEN_SIZE, 8,
        c.GLX_BLUE_SIZE, 8,
        c.GLX_ALPHA_SIZE, 8,
        c.GLX_DEPTH_SIZE, 24,
        c.GLX_STENCIL_SIZE, 8,
        c.GLX_DOUBLEBUFFER,
        c.None
    };
    const vi: *c.XVisualInfo = if (c.glXChooseVisual(display, 0, @ptrCast(&gl_atts))) |v| v else return error.InitFailure;
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

    // OpenGL context
    const glx = c.glXCreateContext(display, vi, null, c.GL_TRUE);
    _ = c.glXMakeCurrent(display, window, glx);

    log.info("Running on Linux with X11", .{});

    return .{
        .display = display,
        .root = root,
        .window = window,
        .width = width,
        .height = height,
        .glx = glx,
        .event = undefined,
        .keycodes = setupKeycodes(display),
        .repeated_keypress = false,
        .atoms = .{
            .wm_protocols = c.XInternAtom(display, "WM_PROTOCOLS", c.False),
            .wm_delete_window = wm_delete_window,
            .net_wm_ping = c.XInternAtom(display, "_NET_WM_PING", c.False),
            .net_wm_state = c.XInternAtom(display, "_NET_WM_STATE", c.False),
            .net_wm_state_fullscreen = c.XInternAtom(display, "_NET_WM_STATE_FULLSCREEN", c.False),
            .net_wm_state_maximized_horz = c.XInternAtom(display, "_NET_WM_STATE_MAXIMIZED_HORZ", c.False),
            .net_wm_state_maximized_vert = c.XInternAtom(display, "_NET_WM_STATE_MAXIMIZED_VERT", c.False),
            .net_wm_bypass_compositor = c.XInternAtom(display, "_NET_WM_BYPASS_COMPOSITOR", c.False),
            .motif_wm_hints = c.XInternAtom(display, "_MOTIF_WM_HINTS", c.False),
        },
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
                // For repeated key presses (when holding key) X11 will send a KeyPress and KeyRelease simultaneously
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
        c.ClientMessage => {
            const msg_type: c.Atom = @intCast(ctx.event.xclient.message_type);
            if (msg_type == ctx.atoms.wm_protocols) {
                // Window manager protocols
                const protocol: c.Atom = @intCast(ctx.event.xclient.data.l[0]);

                if (protocol == ctx.atoms.wm_delete_window) {
                    // Request to close the window
                    return events.Event{
                        .window_close = {},
                    };
                } else if (protocol == ctx.atoms.net_wm_ping) {
                    // Window manager is checking how the window is doing :)
                    ctx.event.xclient.window = ctx.root;
                    _=c.XSendEvent(ctx.display, ctx.root, c.False, c.SubstructureNotifyMask | c.SubstructureRedirectMask, &ctx.event);
                }
            }
        },
        else => {},
    }
    // nothing interesting happened
    return null;
}

// ========== WINDOW FUNCTIONS ==========

pub inline fn setFullscreenMode(ctx: *Context, mode: Window.FullscreenMode) void {
    const fullscreen: c_long, const compositing_bypass: c_char = switch (mode) {
        .windowed => blk: {
            // TODO: make resize_enabled customizable
            setMotifHints(ctx.*, false, true);
            setMaximized(ctx, false);
            break :blk .{0, 0};
        },
        .fullscreen => blk: {
            break :blk .{1, 1};
        },
        .borderless => blk: {
            setMotifHints(ctx.*, true, false);
            setMaximized(ctx, true);
            break :blk .{0, 2};
        },
    };

    _=c.XChangeProperty(ctx.display, ctx.window, ctx.atoms.net_wm_bypass_compositor, c.XA_CARDINAL, 32, c.PropModeReplace, @ptrCast(&compositing_bypass), 1);

    ctx.event = std.mem.zeroes(c.XEvent);
    ctx.event.type = c.ClientMessage;
    ctx.event.xclient.window = ctx.window;
    ctx.event.xclient.display = ctx.display;
    ctx.event.xclient.message_type = ctx.atoms.net_wm_state;
    ctx.event.xclient.format = 32;
    ctx.event.xclient.data.l[0] = fullscreen;
    ctx.event.xclient.data.l[1] = @intCast(ctx.atoms.net_wm_state_fullscreen);
    ctx.event.xclient.data.l[2] = 0;
    ctx.event.xclient.data.l[3] = 1; // source indicator

    _=c.XSendEvent(ctx.display, ctx.root, c.False, c.SubstructureNotifyMask | c.SubstructureRedirectMask, &ctx.event);
}

fn setMotifHints(ctx: Context, borderless: bool, resize_enabled: bool) void {
    const MotifHints = extern struct {
        flags: c_ulong,
        functions: c_ulong,
        decorations: c_ulong,
        input_mode: c_long,
        status: c_ulong,
    };
    const FLAG_FUNCTIONS = 1 << 0;
    const FLAG_DECORATIONS = 1 << 1;

    const FUNC_RESIZE = 1 << 1;
    const FUNC_MOVE = 1 << 2;
    const FUNC_MINIMIZE = 1 << 3;
    const FUNC_MAXIMIZE = 1 << 4;
    const FUNC_CLOSE = 1 << 5;
    const FUNC_ALL = FUNC_RESIZE | FUNC_MOVE | FUNC_MINIMIZE | FUNC_MAXIMIZE | FUNC_CLOSE;

    const DECOR_BORDER = 1 << 1;
    const DECOR_RESIZEH = 1 << 2;
    const DECOR_TITLE = 1 << 3;
    const DECOR_MENU = 1 << 4;
    const DECOR_MINIMIZE = 1 << 5;
    const DECOR_MAXIMIZE = 1 << 6;
    const DECOR_ALL = DECOR_BORDER | DECOR_RESIZEH | DECOR_TITLE | DECOR_MENU | DECOR_MINIMIZE | DECOR_MAXIMIZE;

    var hints = std.mem.zeroes(MotifHints);
    hints.flags = FLAG_DECORATIONS;

    if (!borderless) {
        hints.flags |= FLAG_FUNCTIONS;

        hints.decorations = DECOR_ALL;
        hints.functions = FUNC_ALL;

        if (!resize_enabled) {
            hints.decorations &= ~@as(c_ulong, DECOR_RESIZEH);
            hints.functions &= ~@as(c_ulong, FUNC_RESIZE);
        }
    }

    _=c.XChangeProperty(ctx.display, ctx.window, ctx.atoms.motif_wm_hints, ctx.atoms.motif_wm_hints, 32, c.PropModeReplace, @ptrCast(&hints), 5);
}

pub inline fn setMaximized(ctx: *Context, enable: bool) void {
    ctx.event = std.mem.zeroes(c.XEvent);
    ctx.event.type = c.ClientMessage;
    ctx.event.xclient.window = ctx.window;
    ctx.event.xclient.message_type = ctx.atoms.net_wm_state;
    ctx.event.xclient.format = 32;
    ctx.event.xclient.data.l[0] = @intFromBool(enable);
    ctx.event.xclient.data.l[1] = @intCast(ctx.atoms.net_wm_state_maximized_horz);
    ctx.event.xclient.data.l[2] = @intCast(ctx.atoms.net_wm_state_maximized_vert);
    ctx.event.xclient.data.l[3] = 1; // source indicator

    _=c.XSendEvent(ctx.display, ctx.root, c.False, c.SubstructureRedirectMask | c.SubstructureNotifyMask, &ctx.event);
}

// ========== OTHER ==========

pub inline fn swapBuffers(ctx: Context) void {
    _ = c.glXSwapBuffers(ctx.display, ctx.window);
}

pub const getProcAddress = c.glXGetProcAddress;

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


