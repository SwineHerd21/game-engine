const std = @import("std");

const Window = @import("Window.zig");

pub const Platform = enum {
    X11,
    Windows,
};

pub const platform: Platform = switch (@import("builtin").os.tag) {
    .linux => .X11,
    .windows => .Windows,
    else => |os| @compileError(std.fmt.comptimePrint("Platform is not supported", .{@tagName(os)})),
};

pub fn main() !void {
    const window = try Window.createWindow(800, 600);
    defer window.destroy();

    // Do setup here

    window.runEventLoop();
}

pub fn handleKeypress() void {
    std.debug.print("ASDA", .{});
}
