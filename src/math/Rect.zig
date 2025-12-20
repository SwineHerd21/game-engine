const std = @import("std");
const math = @import("math.zig");

const Rect = @This();

x: i32,
y: i32,
width: i32,
height: i32,

pub inline fn new(x: i32, y: i32, width: i32, height: i32) Rect {
    return .{
        .x = x,
        .y = y,
        .width = width,
        .height = height,
    };
}

/// Construct a rect with two opposite corners at `p1` and `p2`.
pub inline fn fromPoints(p1: math.Vec2i, p2: math.Vec2i) Rect {
    const top_left = @min(p1.simd(), p2.simd());
    const bottom_right = @max(p1.simd(), p2.simd());
    const extend = bottom_right - top_left;
    return .{
        .x = top_left[0],
        .y = top_left[1],
        .width = extend[0],
        .height = extend[1],
    };
}

pub inline fn contains(r: Rect, pos: math.Vec2i) bool {
    return pos.x >= r.x and pos.x <= r.x + r.width
        and pos.y >= r.y and pos.y <= r.y + r.height;
}
