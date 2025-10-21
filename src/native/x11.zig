const lib = @import("../main.zig");

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
};

pub inline fn createWindow(width: u32, height: u32) Context {
    const display = c.XOpenDisplay(null);
    const screen = c.DefaultScreenOfDisplay(display);
    const window = c.XCreateSimpleWindow(display, c.RootWindowOfScreen(screen), 0, 0, width, height, 0, screen.white_pixel, screen.black_pixel);

    _ = c.XClearWindow(display, window);
    _ = c.XMapRaised(display, window);

    _ = c.XSelectInput(display, window, c.KeyPressMask | c.KeyReleaseMask | c.KeymapStateMask | c.ButtonPressMask | c.ButtonReleaseMask | c.PointerMotionMask | c.EnterWindowMask | c.LeaveWindowMask);

    return .{
        // TODO: check for null pointers
        .display = display.?,
        .screen = @ptrCast(screen),
        .window = window,
    };
}

pub inline fn closeWindow(ctx: Context) void {
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
                lib.handleKeypress();
            },
            c.DestroyNotify => running = false,
            else => {},
        }
    }
}

