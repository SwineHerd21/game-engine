//! Floating point mathematical vectors

const std = @import("std");
const assert = std.debug.assert;

const Shared = @import("shared.zig").Shared;

/// A vector with 2 elements of T (must be a float)
pub fn Vec2float(comptime T: type) type {
    assert(@typeInfo(T) == .float);
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

        pub inline fn simd(v: Self) @Vector(2, T) {
            return @bitCast(v);
        }
        pub inline fn fromSimd(v: @Vector(2, T)) Self {
            return @bitCast(v);
        }

        /// The length of the cross product gives the signed area of a parallelogram
        /// constructed with two vectors. This function returns that length.
        pub inline fn cross(a: Self, b: Self) T {
            return a.x*b.y - a.y*b.x;
        }

        /// Returns the angle between the vector and the positive X axis.
        ///
        /// See `angleTo()` for angle between vectors
        pub inline fn angle(v: Self) T {
            return std.math.atan2(v.x, v.y);
        }

        /// Find the angle between two vectors.
        pub inline fn angleTo(a: Self, b: Self) T {
            return std.math.atan2(a.cross(b), a.dot(b));
        }

        const funcs = Shared(Self, T, dimensions);
        pub const splat = funcs.splat;
        pub const neg = funcs.neg;
        pub const abs = funcs.abs;
        pub const add = funcs.add;
        pub const sub = funcs.sub;
        pub const scale = funcs.scale;
        pub const mul = funcs.mul;
        pub const div = funcs.div;
        pub const dot = funcs.dot;
        pub const normalized = funcs.normalized;
        pub const distance = funcs.distance;
        pub const distanceSqr = funcs.distanceSqr;
        pub const lerp = funcs.lerp;
        pub const moveToward = funcs.moveToward;
        pub const reflect = funcs.reflect;
        pub const clampLength = funcs.clampLength;
        pub const length = funcs.length;
        pub const lengthSqr = funcs.lengthSqr;
        pub const eql = funcs.eql;
        pub const approxEqlRel = funcs.approxEqlRel;
        pub const approxEqlAbs = funcs.approxEqlAbs;

        pub fn format(
            self: @This(),
            writer: *std.Io.Writer,
        ) std.Io.Writer.Error!void {
            try funcs.format(self, writer);
        }
    };
}

/// A vector with 3 elements of T (must be a float)
pub fn Vec3float(comptime T: type) type {
    assert(@typeInfo(T) == .float);
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
        pub inline fn fromVec2(v: Vec2float(T), z: T) Self {
            return .{ .x = v.x, .y = v.y, .z = z };
        }

        pub inline fn simd(v: Self) @Vector(3, T) {
            return @bitCast(v);
        }
        pub inline fn fromSimd(v: @Vector(3, T)) Self {
            return @bitCast(v);
        }

        /// Cross (vector) product of two vectors
        ///
        /// Gives a vector perpendicular to both inputs in the direction determined by the left-hand rule.
        pub inline fn cross(a: Self, b: Self) Self {
            return .new(a.y*b.z - a.z*b.y, a.z*b.x - a.x*b.z, a.x*b.y - a.y*b.x);
        }

        /// Find the angle between two vectors.
        pub inline fn angleTo(a: Self, b: Self) T {
            return std.math.atan2(a.cross(b).length(), a.dot(b));
        }

        const funcs = Shared(Self, T, dimensions);
        pub const splat = funcs.splat;
        pub const neg = funcs.neg;
        pub const abs = funcs.abs;
        pub const add = funcs.add;
        pub const sub = funcs.sub;
        pub const scale = funcs.scale;
        pub const mul = funcs.mul;
        pub const div = funcs.div;
        pub const dot = funcs.dot;
        pub const normalized = funcs.normalized;
        pub const distance = funcs.distance;
        pub const distanceSqr = funcs.distanceSqr;
        pub const lerp = funcs.lerp;
        pub const moveToward = funcs.moveToward;
        pub const reflect = funcs.reflect;
        pub const clampLength = funcs.clampLength;
        pub const length = funcs.length;
        pub const lengthSqr = funcs.lengthSqr;
        pub const eql = funcs.eql;
        pub const approxEqlRel = funcs.approxEqlRel;
        pub const approxEqlAbs = funcs.approxEqlAbs;

        pub fn format(
            self: @This(),
            writer: *std.Io.Writer,
        ) std.Io.Writer.Error!void {
            try funcs.format(self, writer);
        }
    };
}

/// A vector with 4 elements of T (must be a float)
pub fn Vec4float(comptime T: type) type {
    assert(@typeInfo(T) == .float);
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
        pub inline fn fromVec3(v: Vec3float(T), w: T) Self {
            return .{ .x = v.x, .y = v.y, .z = v.z, .w = w };
        }

        pub inline fn simd(v: Self) @Vector(4, T) {
            return @bitCast(v);
        }
        pub inline fn fromSimd(v: @Vector(4, T)) Self {
            return @bitCast(v);
        }

        const funcs = Shared(Self, T, dimensions);
        pub const splat = funcs.splat;
        pub const neg = funcs.neg;
        pub const abs = funcs.abs;
        pub const add = funcs.add;
        pub const sub = funcs.sub;
        pub const scale = funcs.scale;
        pub const mul = funcs.mul;
        pub const div = funcs.div;
        pub const dot = funcs.dot;
        pub const normalized = funcs.normalized;
        pub const distance = funcs.distance;
        pub const distanceSqr = funcs.distanceSqr;
        pub const lerp = funcs.lerp;
        pub const moveToward = funcs.moveToward;
        pub const clampLength = funcs.clampLength;
        pub const length = funcs.length;
        pub const lengthSqr = funcs.lengthSqr;
        pub const eql = funcs.eql;
        pub const approxEqlRel = funcs.approxEqlRel;
        pub const approxEqlAbs = funcs.approxEqlAbs;

        pub fn format(
            self: @This(),
            writer: *std.Io.Writer,
        ) std.Io.Writer.Error!void {
            try funcs.format(self, writer);
        }
    };
}

// ========== Tests ==========

const testing = std.testing;
const Vec2f = Vec2float(f32);
const Vec3f = Vec3float(f32);
const Vec4f = Vec4float(f32);
test "Vector layout" {
    const vec2 = Vec2f.new(3.3, -5.0);
    const vec3 = Vec3f.new(3.3, -5.0, 0.23);
    const vec4 = Vec4f.new(3.3, -5.0, 0.23, 14.0);

    const ptr2: *const anyopaque = @ptrCast(&vec2);
    const ptr3: *const anyopaque = @ptrCast(&vec3);
    const ptr4: *const anyopaque = @ptrCast(&vec4);

    const slice2: [*]const f32 = @alignCast(@ptrCast(ptr2));
    const slice3: [*]const f32 = @alignCast(@ptrCast(ptr3));
    const slice4: [*]const f32 = @alignCast(@ptrCast(ptr4));

    try testing.expectEqualSlices(f32, slice2[0..2], &.{3.3, -5.0});
    try testing.expectEqualSlices(f32, slice3[0..3], &.{3.3, -5.0, 0.23});
    try testing.expectEqualSlices(f32, slice4[0..4], &.{3.3, -5.0, 0.23, 14.0});
}

test "Vector SIMD" {
    const vec2 = Vec2f.new(3.3, -5.0);
    const vec3 = Vec3f.new(3.3, -5.0, 0.23);
    const vec4 = Vec4f.new(3.3, -5.0, 0.23, 14.0);

    const vector2 = @Vector(2, f32){3.3, -5.0};
    const vector3 = @Vector(3, f32){3.3, -5.0, 0.23};
    const vector4 = @Vector(4, f32){3.3, -5.0, 0.23, 14.0};

    try testing.expectEqual(vector2, vec2.simd());
    try testing.expectEqual(vector3, vec3.simd());
    try testing.expectEqual(vector4, vec4.simd());

    try testing.expectEqual(vec2, Vec2f.fromSimd(vector2));
    try testing.expectEqual(vec3, Vec3f.fromSimd(vector3));
    try testing.expectEqual(vec4, Vec4f.fromSimd(vector4));
}

test "Vector from lower" {
    const vec2 = Vec2f.new(321, 123);
    const vec3 = Vec3f.fromVec2(vec2, 333);
    const vec4 = Vec4f.fromVec3(vec3, 444);

    try testing.expectEqual(Vec3f.new(321, 123, 333), vec3);
    try testing.expectEqual(Vec4f.new(321, 123, 333, 444), vec4);
}

test "Vector dot" {
    try testing.expectEqual(0, Vec2f.dot(Vec2f.new(1, 0), Vec2f.new(0, 1)));
    try testing.expectEqual(0, Vec3f.dot(Vec3f.new(1, 0, 0), Vec3f.new(0, 1, 0)));
    try testing.expectEqual(0, Vec4f.dot(Vec4f.new(1, 0, 0, 0), Vec4f.new(0, 1, 0, 0)));

    try testing.expectApproxEqRel(12.2, Vec2f.dot(Vec2f.new(2, 3), Vec2f.new(-2, 5.4)), std.math.floatEps(f32));
    try testing.expectApproxEqRel(16.2, Vec3f.dot(Vec3f.new(2, 3, 4), Vec3f.new(-2, 5.4, 1)), std.math.floatEps(f32));
    try testing.expectApproxEqRel(51.2, Vec4f.dot(Vec4f.new(2, 3, 4, 5), Vec4f.new(-2, 5.4, 1, 7)), std.math.floatEps(f32));

    const v2 = Vec2f.new(3, 4);
    const v3 = Vec3f.new(3, 4, -2);
    const v4 = Vec4f.new(3, 4, -2, 0.1);
    try testing.expectEqual(v2.lengthSqr(), v2.dot(v2));
    try testing.expectEqual(v3.lengthSqr(), v3.dot(v3));
    try testing.expectEqual(v4.lengthSqr(), v4.dot(v4));
}

test "Vector length" {
    const v2 = Vec2f.new(3, 4);
    const v3 = Vec3f.new(3, 4, -2);
    const v4 = Vec4f.new(3, 4, -2, 0.1);

    try testing.expectEqual(5, v2.length());
    try testing.expectApproxEqRel(@sqrt(29.0), v3.length(), std.math.floatEps(f32));
    try testing.expectApproxEqRel(@sqrt(29.01), v4.length(), std.math.floatEps(f32));
}

test "Vector lengthSqr" {
    const v2 = Vec2f.new(3, 4);
    const v3 = Vec3f.new(3, 4, -2);
    const v4 = Vec4f.new(3, 4, -2, 0.1);

    try testing.expectEqual(25, v2.lengthSqr());
    try testing.expectEqual(29, v3.lengthSqr());
    try testing.expectEqual(29.01, v4.lengthSqr());
}

test "Vector cross 2D" {
    try testing.expectEqual(-1, Vec2f.new(2, 3).cross(Vec2f.new(3, 4)));
}

test "Vector cross 3D" {
    try testing.expectEqual(Vec3f.forward, Vec3f.right.cross(Vec3f.up));
    try testing.expectEqual(Vec3f.back, Vec3f.up.cross(Vec3f.right));
    try testing.expectEqual(Vec3f.new(18.5, 46, 42), Vec3f.new(2, -4, 3.5).cross(Vec3f.new(8, 5, -9)));
    try testing.expectEqual(Vec3f.new(18.5, 46, 42).neg(), Vec3f.new(8, 5, -9).cross(Vec3f.new(2, -4, 3.5)));
}

test "Vector angle 2D" {
    try testing.expectApproxEqRel(std.math.pi/4.0, Vec2f.one.angle(), std.math.floatEps(f32));
}

test "Vector angle to" {
    try testing.expectApproxEqRel(-std.math.pi/4.0, Vec2f.one.angleTo(Vec2f.right), std.math.floatEps(f32));
    try testing.expectApproxEqRel(std.math.pi/4.0, Vec3f.new(1,1,0).angleTo(Vec3f.right), std.math.floatEps(f32));
}

test "Vector normalized" {
    try testing.expectEqual(Vec2f.right, Vec2f.new(2, 0).normalized());
    try testing.expectEqual(Vec3f.right, Vec3f.new(2, 0, 0).normalized());
    try testing.expectEqual(Vec4f.new(1,0,0,0), Vec4f.new(2, 0, 0, 0).normalized());

    try testing.expect(Vec2f.new(4.0/5.0, 3.0/5.0).approxEqlRel(Vec2f.new(4, 3).normalized()));
    try testing.expect(Vec3f.new(4.0/@sqrt(41.0), 3.0/@sqrt(41.0), 4.0/@sqrt(41.0)).approxEqlRel(Vec3f.new(4, 3, 4).normalized()));
    try testing.expect(Vec4f.new(1.0/2.0,3.0/8.0,1.0/2.0,@sqrt(23.0)/8.0).approxEqlRel(Vec4f.new(4, 3, 4, @sqrt(23.0)).normalized()));
}

test "Vector distance" {
    try testing.expectApproxEqRel(11.580155, Vec2f.new(1.5, 2.25).distance(Vec2f.new(1.44, -9.33)), std.math.floatEps(f32));
    try testing.expectApproxEqRel(12.225645, Vec3f.new(1.5, 2.25, 3.33).distance(Vec3f.new(1.44, -9.33, 7.25)), std.math.floatEps(f32));
    try testing.expectApproxEqRel(13.185977, Vec4f.new(1.5, 2.25, 3.33, 4.44).distance(Vec4f.new(1.44, -9.33, 7.25, -0.5)), std.math.floatEps(f32));
}

test "Vector distanceSqr" {
    try testing.expectApproxEqRel(134.099989824, Vec2f.new(1.5, 2.25).distanceSqr(Vec2f.new(1.44, -9.33)), std.math.floatEps(f32));
    try testing.expectApproxEqRel(149.466395666, Vec3f.new(1.5, 2.25, 3.33).distanceSqr(Vec3f.new(1.44, -9.33, 7.25)), std.math.floatEps(f32));
    try testing.expectApproxEqRel(173.869995666, Vec4f.new(1.5, 2.25, 3.33, 4.44).distanceSqr(Vec4f.new(1.44, -9.33, 7.25, -0.5)), std.math.floatEps(f32));
}

test "Vector lerp" {
    try testing.expectEqual(Vec2f.new(0.5, 0.5), Vec2f.zero.lerp(Vec2f.one, 0.5));
    try testing.expectEqual(Vec3f.new(0.5, 0.5, 0.5), Vec3f.zero.lerp(Vec3f.one, 0.5));
    try testing.expectEqual(Vec4f.new(0.5, 0.5, 0.5, 0.5), Vec4f.zero.lerp(Vec4f.one, 0.5));
}

test "Vector move toward" {
    try testing.expectEqual(Vec2f.new(0.35355338, 0.35355338), Vec2f.zero.moveToward(Vec2f.one.mul(2), 0.5));
    try testing.expectEqual(Vec3f.new(0.28867513, 0.28867513, 0.28867513), Vec3f.zero.moveToward(Vec3f.one.mul(2), 0.5));
    try testing.expectEqual(Vec4f.new(0.25, 0.25, 0.25, 0.25), Vec4f.zero.moveToward(Vec4f.one.mul(2), 0.5));
}

test "Vector reflect" {
    try testing.expectEqual(Vec2f.new(1, 4), Vec2f.new(1, -4).reflect(Vec2f.up));
    try testing.expectEqual(Vec3f.new(1, -5.92, 2.44), Vec3f.new(1, -4, 5).reflect(Vec3f.new(0, 0.6, 0.8)));
}

test "Vector clampLength" {
    try testing.expectEqual(Vec2f.normalized(Vec2f.one), Vec2f.clampLength(Vec2f.one, 1));
    try testing.expectEqual(Vec3f.normalized(Vec3f.one), Vec3f.clampLength(Vec3f.one, 1));
    try testing.expectEqual(Vec4f.normalized(Vec4f.one), Vec4f.clampLength(Vec4f.one, 1));
}

test "Vector format" {
    try testing.expectEqualStrings("(0, -1)", std.fmt.comptimePrint("{f}", .{comptime Vec2f.new(0.0, -1.0)}));
    try testing.expectEqualStrings("(0, -1, 2.3)", std.fmt.comptimePrint("{f}", .{comptime Vec3f.new(0.0, -1.0, 2.3)}));
    try testing.expectEqualStrings("(0, -1, 2.3, 12.4)", std.fmt.comptimePrint("{f}", .{comptime Vec4f.new(0.0, -1.0, 2.3, 12.4)}));
}
