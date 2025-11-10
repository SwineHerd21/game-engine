//! Keeps track of time passed between frames and since start of execution.
//!
//! For any other timing needs use 'std.time'

const std = @import("std");

const Timer = std.time.Timer;
const EngineError = @import("lib.zig").EngineError;

const log = std.log.scoped(.engine);

const Time = @This();

/// Time since the last frame in seconds
deltaTime: f32,
/// Total application runtime in seconds
totalRuntime: f32,
timer: Timer,

pub fn init() EngineError!Time {
    return .{
        .deltaTime = 0,
        .totalRuntime = 0,
        .timer = Timer.start() catch {
            log.err("Failed to initialize timer", .{});
            return EngineError.InitFailure;
        },
    };
}

pub fn update(self: *Time) void {
    const dt: f32 = @as(f32, @floatFromInt(self.timer.lap())) / @as(f32, std.time.ns_per_s);
    self.deltaTime = dt;
    self.totalRuntime += dt;
}
