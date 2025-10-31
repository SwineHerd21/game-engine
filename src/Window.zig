//! A high-level platform independent representation of a window.
const std = @import("std");

const lib = @import("lib.zig");
const events = @import("events.zig");
const native = @import("platform.zig").native;

const Window = @This();

/// Platform-specific implementation, do not assume anything about its contents.
inner: native.Context,
width: u32,
height: u32,
/// Set to true when you want to close the window.
/// Note: you can set this to false again if you want to prevent the user from closing the app.
should_close: bool = false,

/// Call Window.destroy when the window is no longer needed.
pub fn createWindow(width: u32, height: u32, title: []const u8) !Window {
    // TODO: error handling
    return .{
        .inner = native.createWindow(width, height, title),
        .width = width,
        .height = height,
    };
}

pub fn destroy(w: Window) void {
    native.closeWindow(w.inner);
}

/// Consume the next OS event
pub fn consumeEvent(w: *Window) ?events.Event {
    return native.consumeEvent(w);
}

pub fn swapBuffers(w: Window) void {
    return native.swapBuffers(w.inner);
}

