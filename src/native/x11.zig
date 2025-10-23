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

pub inline fn createWindow(width: u32, height: u32) Context {
    const display = c.XOpenDisplay(null);
    const screen = c.DefaultScreenOfDisplay(display);
    const window = c.XCreateSimpleWindow(display, c.RootWindowOfScreen(screen), 0, 0, width, height, 0, screen.white_pixel, screen.black_pixel);

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

pub inline fn consumeEvent(window: *Window) ?*anyopaque {
    _ = c.XNextEvent(window.inner.display, &window.inner.event);
    switch (window.inner.event.type) {
        c.KeymapNotify => _ = c.XRefreshKeyboardMapping(&window.inner.event.xmapping),
        c.KeyPress => {
            return @ptrCast(&events.KeyPressEvent{
                .keycode = 123,
            });
        },
        c.KeyRelease => {
            window.handleKeyRelease();
        },
        c.ButtonPress => {
            window.handlePointerButtonPress();
        },
        c.ButtonRelease => {
            window.handlePointerButtonRelease();
        },
        c.MotionNotify => {
            window.handlePointerMotion();
        },
        c.EnterNotify => {
            window.handlePointerEnter();
        },
        c.LeaveNotify => {
            window.handlePointerExit();
        },
        c.FocusIn => {
            window.handleGainFocus();
        },
        c.FocusOut => {
            window.handleLoseFocus();
        },
        c.ConfigureNotify => {
            const ev = window.inner.event.xconfigure;

            if (ev.width != window.width or ev.height != window.height) {
                window.handleResize(@intCast(ev.width), @intCast(ev.height));
            }
        },
        c.DestroyNotify => {
            window.should_close = true;
            window.handleClose();
        },
        // Weird thing needed for the 'x' button on the window to be usable
        c.ClientMessage => if (@as(c.Atom, @intCast(window.inner.event.xclient.data.l[0])) == window.inner.wm_delete_window) {
            window.should_close = true;
            window.handleClose();
        },
        else => {},
    }
    return null;
}

