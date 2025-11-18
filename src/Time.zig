//! Keeps track of time passed between frames and since start of execution.
//!
//! For any other timing needs use `std.time`

const std = @import("std");

const Timer = std.time.Timer;
const EngineError = @import("lib.zig").EngineError;

const log = std.log.scoped(.engine);

const Time = @This();

/// Time since the last frame in nanoseconds
dtNano: u64,
/// Total application runtime in nanoseconds
runtimeNano: u64,
/// Internal time keeper, do not touch
timer: Timer,

pub fn init() EngineError!Time {
    return .{
        .dtNano = 0,
        .runtimeNano = 0,
        .timer = Timer.start() catch {
            log.err("Failed to initialize timer", .{});
            return EngineError.InitFailure;
        },
    };
}

pub fn update(self: *Time) void {
    const dt = self.timer.lap();
    self.dtNano = dt;
    self.runtimeNano += dt;
}

/// Gives time since last frame in seconds
pub inline fn deltaTime(self: Time) f64 {
    return @as(f64, @floatFromInt(self.dtNano)) / @as(f64, std.time.ns_per_s);
}

/// Gives total application runtime in seconds
pub inline fn totalRuntime(self: Time) f64 {
    return @as(f64, @floatFromInt(self.runtimeNano)) / @as(f64, std.time.ns_per_s);
}
