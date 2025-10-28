const std = @import("std");

const Window = @import("Window.zig");
pub const App = @import("App.zig");
pub const events = @import("events.zig");
pub const Event = events.Event;

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
pub fn runApplication(app: App) !void {
    try app.run();
}
