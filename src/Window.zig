//! A high-level platform independent representation of a window.

const lib = @import("main.zig");
const Window = @This();

const x11 = @import("native/x11.zig");

/// Platform-specific implementation
inner: switch (lib.platform) {
    .X11 => x11.Context,
    .Windows => unreachable,
},

/// Call Window.destroy when the window is no longer needed.
pub fn createWindow(width: u32, height: u32) !Window {
    // TODO: error handling
    switch (lib.platform) {
        .X11 => return .{ .inner = x11.createWindow(width, height) },
        .Windows => unreachable,
    }
}

pub fn destroy(w: Window) void {
    switch (lib.platform) {
        .X11 => x11.closeWindow(w.inner),
        .Windows => unreachable,
    }
}

/// Start handling window events.
///
/// NOTE: runs in a loop until the window handles a close/destroy event.
/// Make sure to do all setup before calling this.
pub fn runEventLoop(w: Window) void {
    switch (lib.platform) {
        .X11 => x11.runEventLoop(w.inner),
        .Windows => unreachable,
    }
}
