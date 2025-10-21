const lib = @import("main.zig");
const Window = @This();

const x11 = @import("native/x11.zig");

/// Platform-specific window
inner: switch (lib.platform) {
    .X11 => x11.Context,
    .Windows => unreachable,
},

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

pub fn runEventLoop(w: Window) void {
    switch (lib.platform) {
        .X11 => x11.runEventLoop(w.inner),
        .Windows => unreachable,
    }
}
