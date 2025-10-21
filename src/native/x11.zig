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
    /// Handles closing the window with 'x' button
    wm_delete_window: c.Atom,
};

// TODO: Error handling probably?

pub inline fn createWindow(width: u32, height: u32) Context {
    const display = c.XOpenDisplay(null);
    const screen = c.DefaultScreenOfDisplay(display);
    const window = c.XCreateSimpleWindow(display, c.RootWindowOfScreen(screen), 0, 0, width, height, 0, screen.white_pixel, screen.black_pixel);

    _ = c.XClearWindow(display, window);
    _ = c.XMapRaised(display, window);

    _ = c.XSelectInput(display, window, c.KeymapStateMask | c.KeyPressMask | c.KeyReleaseMask | c.ButtonPressMask | c.ButtonReleaseMask | c.PointerMotionMask | c.EnterWindowMask | c.LeaveWindowMask | c.FocusChangeMask);

    const wm_delete_window = c.XInternAtom(display, "WM_DELETE_WINDOW", 0);
    _ = c.XSetWMProtocols(display, window, @constCast(&wm_delete_window), 1);

    return .{
        // TODO: check for null pointers
        .display = display.?,
        .screen = @ptrCast(screen),
        .window = window,
        .wm_delete_window = wm_delete_window,
    };
}

pub inline fn closeWindow(ctx: Context) void {
    _ = c.XUnmapWindow(ctx.display, ctx.window);
    _ = c.XDestroyWindow(ctx.display, ctx.window);
    _ = c.XCloseDisplay(ctx.display);
}

pub inline fn runEventLoop(ctx: Context) void {
    var ev: c.XEvent = undefined;
    var running = true;
    while (running) {
        _ = c.XNextEvent(ctx.display, &ev);
        switch (ev.type) {
            c.KeymapNotify => _ = c.XRefreshKeyboardMapping(&ev.xmapping),
            c.KeyPress => {
                events.handleKeyPress();
            },
            c.KeyRelease => {
                events.handleKeyRelease();
            },
            c.ButtonPress => {
                events.handlePointerButtonPress();
            },
            c.ButtonRelease => {
                events.handlePointerButtonRelease();
            },
            c.MotionNotify => {
                events.handlePointerMotion();
            },
            c.EnterNotify => {
                events.handlePointerEnter();
            },
            c.LeaveNotify => {
                events.handlePointerExit();
            },
            c.FocusIn => {
                events.handleGainFocus();
            },
            c.FocusOut => {
                events.handleLoseFocus();
            },
            c.DestroyNotify => running = false,
            // Weird thing needed for the 'x' button on the window to be usable
            c.ClientMessage => if (@as(c.Atom, @intCast(ev.xclient.data.l[0])) == ctx.wm_delete_window) {
                running = false;
            },
            else => {},
        }
    }
}

