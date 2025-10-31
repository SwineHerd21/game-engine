const std = @import("std");

pub const Platform = enum {
    X11,
    Windows,
};

pub const platform: Platform = switch (@import("builtin").os.tag) {
    .linux => .X11,
    .windows => .Windows,
    else => |os| @compileError(std.fmt.comptimePrint("Platform {} is not supported", .{@tagName(os)})),
};

pub const native = switch (platform) {
    .X11 => @import("native/x11.zig"),
    .Windows => unreachable,
};
