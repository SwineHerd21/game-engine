//! Keeps track of time passed between frames and since start of execution.
//!
//! For any other timing needs use `std.time`

const std = @import("std");

const Timer = std.time.Timer;
const EngineError = @import("lib.zig").EngineError;

const log = std.log.scoped(.engine);

const Time = @This();

/// Time since the last frame in nanoseconds
dt_nano: u64,
/// Total application runtime in nanoseconds
runtime_nano: u64,
/// Internal time keeper, do not touch
timer: Timer,

pub fn init() EngineError!Time {
    return .{
        .dt_nano = 0,
        .runtime_nano = 0,
        .timer = Timer.start() catch {
            log.err("Failed to initialize timer", .{});
            return error.InitFailure;
        },
    };
}

pub fn update(self: *Time) void {
    const dt = self.timer.lap();
    self.dt_nano = dt;
    self.runtime_nano += dt;
}

/// Gives time since last frame in seconds
pub inline fn deltaTime(self: Time) f32 {
    return @as(f32, @floatFromInt(self.dt_nano)) / @as(f32, std.time.ns_per_s);
}

/// Gives total application runtime in seconds
pub inline fn totalRuntime(self: Time) f32 {
    return @as(f32, @floatFromInt(self.runtime_nano)) / @as(f32, std.time.ns_per_s);
}
