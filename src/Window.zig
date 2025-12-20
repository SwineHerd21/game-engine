//! A high-level platform independent representation of a window.
const std = @import("std");

const events = @import("events.zig");
const native = @import("platform.zig").native;
const math = @import("math/math.zig");

const Input = @import("Input.zig");
const EngineError = @import("lib.zig").EngineError;

const Window = @This();

/// Platform-specific implementation, do not assume anything about its contents.
inner: native.Context,
/// Set to true when you want to close the window.
/// Note: you can set this to false again if you want to prevent the user from closing the app.
should_close: bool = false,

pub const FullscreenMode = enum {
    windowed,
    fullscreen,
    borderless,
};

/// Call `destroy()` when the window is no longer needed.
pub fn create(width: u32, height: u32, title: []const u8) EngineError!Window {
    return .{
        .inner = try native.createWindow(width, height, title),
    };
}

pub fn destroy(w: Window) void {
    native.closeWindow(w.inner);
}

pub fn areEventsPending(w: Window) bool {
    return native.areEventsPending(w.inner);
}

/// Consume the next OS event
pub fn consumeEvent(w: *Window) ?events.Event {
    return native.consumeEvent(&w.inner);
}

pub fn swapBuffers(w: Window) void {
    return native.swapBuffers(w.inner);
}

pub fn setFullscreenMode(w: *Window, mode: FullscreenMode) void {
    return native.setFullscreenMode(&w.inner, mode);
}

pub fn setMaximized(w: *Window, maximize: bool) void {
    return native.setMaximized(&w.inner, maximize);
}

pub fn setPointerLock(w: Window, lock: bool) void {
    return native.setPointerLock(w.inner, lock);
}

pub fn warpPointer(w: Window, pos: math.Vec2i) void {
    return native.warpPointer(w.inner, pos);
}

/// Returns the pointer position relative to the window. If the pointer is not on the same screen
/// as the window, returns (0, 0)
pub fn getPointerPosition(w: Window) math.Vec2i {
    return native.getPointerPosition(w.inner);
}
