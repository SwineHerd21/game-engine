//! Signed integer mathematical vectors

const std = @import("std");
const assert = std.debug.assert;

const Shared = @import("shared.zig").Shared;
const vecf = @import("vecf.zig");
const Vec2float = vecf.Vec2float;
const Vec3float = vecf.Vec3float;
const Vec4float = vecf.Vec4float;

/// A vector with 2 elements of T (must be a signed integer)
pub fn Vec2int(comptime T: type) type {
    assert(@typeInfo(T) == .int);
    assert(@typeInfo(T).int.signedness == .signed);
    return extern struct {
        const Self = @This();
        pub const dimensions = 2;

        x: T,
        y: T,

        pub const zero: Self = .splat(0);
        pub const right: Self = .new(1, 0);
        pub const left: Self = .new(-1, 0);
        pub const up: Self = .new(0, 1);
        pub const down: Self = .new(0, -1);
        pub const one: Self = .splat(1);

        pub inline fn new(x: T, y: T) Self {
            return .{ .x = x, .y = y };
        }

        pub inline fn toFloat(v: Self, float_type: type) Vec2float(float_type) {
            return .{ .x = @floatFromInt(v.x), .y = @floatFromInt(v.y) };
        }

        /// The length of the cross product gives the signed area of a parallelogram
        /// constructed with two vectors. This function returns that length.
        pub inline fn cross(a: Self, b: Self) T {
            return a.x*b.y - a.y*b.x;
        }

        /// Returns the angle between the vector and the positive X axis. `return_type` must be `f32` or `f64`.
        ///
        /// See `angleTo()` for angle between vectors
        pub inline fn angle(v: Self, return_type: type) return_type {
            return std.math.atan2(@as(return_type, @floatFromInt(v.x)), @as(return_type, @floatFromInt(v.y)));
        }

        /// Find the angle between two vectors. `return_type` must be `f32` or `f64`.
        pub inline fn angleTo(a: Self, b: Self, return_type: type) return_type {
            return std.math.atan2(@as(return_type, @floatFromInt(a.cross(b))), @as(return_type, @floatFromInt(a.dot(b))));
        }

        const funcs = Shared(Self, T, dimensions);
        pub const splat = funcs.splat;
        pub const neg = funcs.neg;
        pub const abs = funcs.abs;
        pub const add = funcs.add;
        pub const sub = funcs.sub;
        pub const scale = funcs.scale;
        pub const mul = funcs.mul;
        pub const div = funcs.divTrunc;
        pub const dot = funcs.dot;
        pub const distanceSqr = funcs.distanceSqr;
        pub const lengthSqr = funcs.lengthSqr;
        pub const eql = funcs.eql;

        pub fn format(
            self: @This(),
            writer: *std.Io.Writer,
        ) std.Io.Writer.Error!void {
            try funcs.format(self, writer);
        }
    };
}

/// A vector with 3 elements of T (must be an integer)
pub fn Vec3int(comptime T: type) type {
    assert(@typeInfo(T) == .int);
    assert(@typeInfo(T).int.signedness == .signed);
    return extern struct {
        const Self = @This();
        pub const dimensions = 3;

        x: T,
        y: T,
        z: T,

        pub const zero: Self = .splat(0);
        pub const right: Self = .new(1, 0, 0);
        pub const left: Self = .new(-1, 0, 0);
        pub const up: Self = .new(0, 1, 0);
        pub const down: Self = .new(0, -1, 0);
        pub const forward: Self = .new(0, 0, 1);
        pub const back: Self = .new(0, 0, -1);
        pub const one: Self = .splat(1);

        pub inline fn new(x: T, y: T, z: T) Self {
            return .{ .x = x, .y = y, .z = z };
        }
        pub inline fn fromVec2(v: Vec2int(T), z: T) Self {
            return .{ .x = v.x, .y = v.y, .z = z };
        }

        pub inline fn toFloat(v: Self, float_type: type) Vec3float(float_type) {
            return .{ .x = @floatFromInt(v.x), .y = @floatFromInt(v.y), .z = @floatFromInt(v.z) };
        }

        /// Cross (vector) product of two vectors
        ///
        /// Gives a vector perpendicular to both inputs in the direction determined by the left-hand rule.
        pub inline fn cross(a: Self, b: Self) Self {
            return .new(a.y*b.z - a.z*b.y, a.z*b.x - a.x*b.z, a.x*b.y - a.y*b.x);
        }

        /// Find the angle between two vectors. `return_type` must be `f32` or `f64`.
        pub inline fn angleTo(a: Self, b: Self, return_type: type) return_type {
            return std.math.atan2(@sqrt(@as(return_type, @floatFromInt(a.cross(b).lengthSqr()))), @as(return_type, @floatFromInt(a.dot(b))));
        }

        const funcs = Shared(Self, T, dimensions);
        pub const splat = funcs.splat;
        pub const neg = funcs.neg;
        pub const abs = funcs.abs;
        pub const add = funcs.add;
        pub const sub = funcs.sub;
        pub const scale = funcs.scale;
        pub const mul = funcs.mul;
        pub const div = funcs.divTrunc;
        pub const dot = funcs.dot;
        pub const distanceSqr = funcs.distanceSqr;
        pub const lengthSqr = funcs.lengthSqr;
        pub const eql = funcs.eql;

        pub fn format(
            self: @This(),
            writer: *std.Io.Writer,
        ) std.Io.Writer.Error!void {
            try funcs.format(self, writer);
        }
    };
}

/// A vector with 4 elements of T (must be an integer)
pub fn Vec4int(comptime T: type) type {
    assert(@typeInfo(T) == .int);
    assert(@typeInfo(T).int.signedness == .signed);
    return extern struct {
        const Self = @This();
        pub const dimensions = 4;

        x: T,
        y: T,
        z: T,
        w: T,

        pub const zero: Self = .splat(0);
        pub const one: Self = .splat(1);

        pub inline fn new(x: T, y: T, z: T, w: T) Self {
            return .{ .x = x, .y = y, .z = z, .w = w };
        }
        pub inline fn fromVec3(v: Vec3int(T), w: T) Self {
            return .{ .x = v.x, .y = v.y, .z = v.z, .w = w };
        }

        pub inline fn toFloat(v: Self, float_type: type) Vec4float(float_type) {
            return .{ .x = @floatFromInt(v.x), .y = @floatFromInt(v.y), .z = @floatFromInt(v.z), .w = @floatFromInt(v.w) };
        }

        const funcs = Shared(Self, T, dimensions);
        pub const splat = funcs.splat;
        pub const neg = funcs.neg;
        pub const abs = funcs.abs;
        pub const add = funcs.add;
        pub const sub = funcs.sub;
        pub const scale = funcs.scale;
        pub const mul = funcs.mul;
        pub const div = funcs.divTrunc;
        pub const dot = funcs.dot;
        pub const distanceSqr = funcs.distanceSqr;
        pub const lengthSqr = funcs.lengthSqr;
        pub const eql = funcs.eql;

        pub fn format(
            self: @This(),
            writer: *std.Io.Writer,
        ) std.Io.Writer.Error!void {
            try funcs.format(self, writer);
        }
    };
}

// ========== Testing ==========

const testing = std.testing;
const Vec2i = Vec2int(i32);
const Vec3i = Vec3int(i32);
const Vec4i = Vec4int(i32);
test "Vector int from lower" {
    const vec2 = Vec2i.new(321, 123);
    const vec3 = Vec3i.fromVec2(vec2, 333);
    const vec4 = Vec4i.fromVec3(vec3, 444);

    try testing.expectEqual(Vec3i.new(321, 123, 333), vec3);
    try testing.expectEqual(Vec4i.new(321, 123, 333, 444), vec4);
}

test "Vector int lengthSqr" {
    const v2 = Vec2i.new(3, 4);
    const v3 = Vec3i.new(3, 4, -2);
    const v4 = Vec4i.new(3, 4, -2, 1);

    try testing.expectEqual(25, v2.lengthSqr());
    try testing.expectEqual(29, v3.lengthSqr());
    try testing.expectEqual(30, v4.lengthSqr());
}

test "Vector int cross 2D" {
    try testing.expectEqual(-1, Vec2i.new(2, 3).cross(Vec2i.new(3, 4)));
}

test "Vector int cross 3D" {
    try testing.expectEqual(Vec3i.forward, Vec3i.right.cross(Vec3i.up));
    try testing.expectEqual(Vec3i.back, Vec3i.up.cross(Vec3i.right));
}

test "Vector int angle 2D" {
    try testing.expectApproxEqRel(std.math.pi/4.0, Vec2i.one.angle(f32), std.math.floatEps(f32));
}

test "Vector int angle to" {
    try testing.expectApproxEqRel(-std.math.pi/4.0, Vec2i.one.angleTo(Vec2i.right, f32), std.math.floatEps(f32));
    try testing.expectApproxEqRel(std.math.pi/4.0, Vec3i.new(1,1,0).angleTo(Vec3i.right, f32), std.math.floatEps(f32));
}

test "Vector int to float" {
    try testing.expectEqual(Vec3float(f32).new(1.0, -1.0, 2.0), Vec3i.new(1, -1, 2).toFloat(f32));
}
