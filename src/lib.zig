const std = @import("std");

const Window = @import("Window.zig");

pub const Platform = enum {
    X11,
    Windows,
};

pub const platform: Platform = switch (@import("builtin").os.tag) {
    .linux => .X11,
    .windows => .Windows,
    else => |os| @compileError(std.fmt.comptimePrint("Platform {} is not supported", .{@tagName(os)})),
};

/// Call this function when you are done setting up your application.
///
/// WARNING: This places the thread into an infinite update loop until the window closes.
pub fn runApplication() !void {
    var window = try Window.createWindow(800, 600);
    defer window.destroy();

    // Do setup here

    while (!window.should_close) {
        window.consumeEvent();
    }

    std.log.info("Shutting down engine...", .{}); 
}

