//! A high-level platform independent representation of a window.
const std = @import("std");

const lib = @import("lib.zig");
const Window = @This();

const x11 = @import("native/x11.zig");

/// Platform-specific implementation
inner: switch (lib.platform) {
    .X11 => x11.Context,
    .Windows => unreachable,
},
width: u16,
height: u16,
/// Set to true when you want to close the window.
should_close: bool = false,

/// Call Window.destroy when the window is no longer needed.
pub fn createWindow(width: u32, height: u32) !Window {
    // TODO: error handling
    switch (lib.platform) {
        .X11 => return .{
            .inner = x11.createWindow(width, height),
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
pub fn consumeEvent(w: *Window) ?*anyopaque {
    switch (lib.platform) {
        .X11 => return x11.consumeEvent(w),
        .Windows => unreachable,
    }
}

pub fn handleKeyPress(self: *Window) void {
    std.debug.print("ASD ", .{});
    _=self;
}

pub fn handleKeyRelease(self: *Window) void {
    std.debug.print("DSA ", .{});
    _=self;
}

pub fn handlePointerButtonPress(self: *Window) void {
    std.debug.print("mouse ", .{});
    _=self;
}

pub fn handlePointerButtonRelease(self: *Window) void {
    std.debug.print("esuom ", .{});
    _=self;
}

pub fn handlePointerMotion(self: *Window) void {
    std.debug.print("m", .{});
    _=self;
}

pub fn handlePointerEnter(self: *Window) void {
    std.debug.print("entered ", .{});
    _=self;
}

pub fn handlePointerExit(self: *Window) void {
    std.debug.print("exited ", .{});
    _=self;
}

pub fn handleGainFocus(self: *Window) void {
    std.debug.print("focused ", .{});
    _=self;
}

pub fn handleLoseFocus(self: *Window) void {
    std.debug.print("unfocused ", .{});
    _=self;
}

pub fn handleClose(self: *Window) void {
    std.debug.print("closing\n", .{});
    _=self;
}

pub fn handleResize(self: *Window, new_width: u32, new_height: u32) void {
    std.debug.print("resized ", .{});
    
    self.width = new_width;
    self.height = new_height;
}
