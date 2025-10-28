//! A high-level platform independent representation of a window.
const std = @import("std");

const lib = @import("lib.zig");
const events = @import("events.zig");
const x11 = @import("native/x11.zig");

const Window = @This();


/// Platform-specific implementation
inner: switch (lib.platform) {
    .X11 => x11.Context,
    .Windows => unreachable,
},
width: u32,
height: u32,
/// Set to true when you want to close the window.
should_close: bool = false,

/// Call Window.destroy when the window is no longer needed.
pub fn createWindow(width: u32, height: u32, title: []const u8) !Window {
    // TODO: error handling
    switch (lib.platform) {
        .X11 => return .{
            .inner = x11.createWindow(width, height, title),
            .width = width,
            .height = height,
        },
        .Windows => unreachable,
    }
}

pub fn destroy(w: Window) void {
    switch (lib.platform) {
        .X11 => x11.closeWindow(w.inner),
        .Windows => unreachable,
    }
}

/// Consume the next OS event
pub fn consumeEvent(w: *Window) ?events.Event {
    switch (lib.platform) {
        .X11 => return x11.consumeEvent(w),
        .Windows => unreachable,
    }
}

