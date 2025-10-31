//! A high-level platform independent representation of a window.
const std = @import("std");

const lib = @import("lib.zig");
const events = @import("events.zig");
const native = switch (lib.platform) {
    .X11 => @import("native/x11.zig"),
    .Windows => unreachable,
};

const Window = @This();


/// Platform-specific implementation
inner: native.Context,
width: u32,
height: u32,
/// Set to true when you want to close the window.
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

