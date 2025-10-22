const std = @import("std");

const engine = @import("engine");

pub fn main() !void {
    std.debug.print("gaming", .{});
    // Setup game here

    try engine.runApplication();
}
