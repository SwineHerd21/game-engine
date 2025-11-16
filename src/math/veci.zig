//! Signed integer mathematical vectors

const std = @import("std");
const Shared = @import("vecf.zig").Shared;

/// A vector with 2 elements of i32
pub const Vec2i = extern struct {
    const Vec = @This();
    const N = 2;
    const T = i32;

    v: [N]T,

    pub const zero: Vec = .splat(0);
    pub const right: Vec = .new(1, 0);
    pub const left: Vec = .new(-1, 0);
    pub const up: Vec = .new(0, 1);
    pub const down: Vec = .new(0, -1);
    pub const one: Vec = .splat(1);

    pub inline fn new(_x: T, _y: T) Vec {
        return .{ .v = .{_x,_y} };
    }

    pub inline fn x(v: Vec) T {
        return v.v[0];
    }
    pub inline fn y(v: Vec) T {
        return v.v[1];
    }

    /// The length of the cross product gives the signed area of a parallelogram
    /// constructed with two vectors. This function returns that length.
    pub inline fn cross(a: Vec, b: Vec) T {
        return a.x()*b.y() - a.y()*b.x();
    }

    /// Returns the angle between the vector and the positive X axis.
    ///
    /// See `angle_to()` for angle between vectors
    pub inline fn angle(v: Vec) f32 {
        return std.math.atan2(@as(f32, @floatFromInt(v.x())), @as(f32, @floatFromInt(v.y())));
    }

    /// Find the angle between two vectors.
    pub inline fn angleTo(a: Vec, b: Vec) f32 {
        return std.math.atan2(@as(f32, @floatFromInt(a.cross(b))), @as(f32, @floatFromInt(a.dot(b))));
    }

    const funcs = Shared(Vec, N, T);
    const funcsi = Sharedi(Vec, N, T);
    pub const splat = funcs.splat;
    pub const negate = funcs.negate;
    pub const add = funcs.add;
    pub const sub = funcs.sub;
    pub const scale = funcs.scale;
    pub const mul = funcs.mul;
    pub const div = funcs.div;
    pub const dot = funcs.dot;
    pub const distance = funcs.distance;
    pub const distanceSqr = funcs.distanceSqr;
    pub const length = funcsi.length;
    pub const lengthSqr = funcs.lengthSqr;
    pub const eql = funcs.eql;

    pub fn format(
        self: @This(),
        writer: *std.Io.Writer,
    ) std.Io.Writer.Error!void {
        try writer.print("({}, {})", .{self.x(), self.y()});
    }
};

/// A vector with 3 elements of i32
pub const Vec3i = extern struct {
    const Vec = @This();
    const N = 3;
    const T = i32;

    v: [N]T,

    pub const zero: Vec = .splat(0);
    pub const right: Vec = .new(1, 0, 0);
    pub const left: Vec = .new(-1, 0, 0);
    pub const up: Vec = .new(0, 1, 0);
    pub const down: Vec = .new(0, -1, 0);
    pub const forward: Vec = .new(0, 0, 1);
    pub const back: Vec = .new(0, 0, -1);
    pub const one: Vec = .splat(1);

    pub inline fn new(_x: T, _y: T, _z: T) Vec {
        return .{ .v = .{_x,_y,_z} };
    }
    pub inline fn fromVec2(v: Vec2i, _z: T) Vec {
        return .{ .v = .{v.x(),v.y(),_z} };
    }

    pub inline fn x(v: Vec) T {
        return v.v[0];
    }
    pub inline fn y(v: Vec) T {
        return v.v[1];
    }
    pub inline fn z(v: Vec) T {
        return v.v[2];
    }

    /// Cross (vector) product of two vectors
    ///
    /// Gives a vector perpendicular to both inputs in the direction determined by the left-hand rule.
    pub inline fn cross(a: Vec, b: Vec) Vec {
        return .new(a.y()*b.z() - a.z()*b.y(), a.z()*b.x() - a.x()*b.z(), a.x()*b.y() - a.y()*b.x());
    }

    /// Find the angle between two vectors.
    pub inline fn angleTo(a: Vec, b: Vec) f32 {
        return std.math.atan2(a.cross(b).length(), @as(f32, @floatFromInt(a.dot(b))));
    }

    const funcs = Shared(Vec, N, T);
    const funcsi = Sharedi(Vec, N, T);
    pub const splat = funcs.splat;
    pub const negate = funcs.negate;
    pub const add = funcs.add;
    pub const sub = funcs.sub;
    pub const scale = funcs.scale;
    pub const mul = funcs.mul;
    pub const div = funcs.div;
    pub const dot = funcs.dot;
    pub const distance = funcs.distance;
    pub const distanceSqr = funcs.distanceSqr;
    pub const length = funcsi.length;
    pub const lengthSqr = funcs.lengthSqr;
    pub const eql = funcs.eql;

    pub fn format(
        self: @This(),
        writer: *std.Io.Writer,
    ) std.Io.Writer.Error!void {
        try writer.print("({}, {}, {})", .{self.x(), self.y(), self.z()});
    }
};

/// A vector with 4 elements of i32
pub const Vec4i = extern struct {
    const Vec = @This();
    const N = 4;
    const T = i32;

    v: [N]T,

    pub const zero: Vec = .splat(0);
    pub const one: Vec = .splat(1);

    pub inline fn new(_x: T, _y: T, _z: T, _w: T) Vec {
        return .{ .v = .{_x,_y,_z,_w} };
    }
    pub inline fn fromVec3(v: Vec3i, _w: T) Vec {
        return .{ .v = .{v.x(),v.y(),v.z(),_w} };
    }

    pub inline fn x(v: Vec) T {
        return v.v[0];
    }
    pub inline fn y(v: Vec) T {
        return v.v[1];
    }
    pub inline fn z(v: Vec) T {
        return v.v[2];
    }
    pub inline fn w(v: Vec) T {
        return v.v[3];
    }

    const funcs = Shared(Vec, N, T);
    const funcsi = Sharedi(Vec, N, T);
    pub const splat = funcs.splat;
    pub const negate = funcs.negate;
    pub const add = funcs.add;
    pub const sub = funcs.sub;
    pub const scale = funcs.scale;
    pub const mul = funcs.mul;
    pub const div = funcs.div;
    pub const dot = funcs.dot;
    pub const distance = funcs.distance;
    pub const distanceSqr = funcs.distanceSqr;
    pub const length = funcsi.length;
    pub const lengthSqr = funcs.lengthSqr;
    pub const eql = funcs.eql;

    pub fn format(
        self: @This(),
        writer: *std.Io.Writer,
    ) std.Io.Writer.Error!void {
        try writer.print("({}, {}, {}, {})", .{self.x(), self.y(), self.z(), self.w()});
    }
};

fn Sharedi(Vec: type, N: comptime_int, T: type) type {
    std.debug.assert(@hasField(Vec, "v") and @FieldType(Vec, "v") == [N]T);
    return extern struct {
        pub inline fn length(v: Vec) f32 {
            var result: T = 0;
            inline for (0..N) |i| {
                result += v.v[i]*v.v[i];
            }
            return @sqrt(@as(f32, @floatFromInt(result)));
        }
    };
}

const testing = std.testing;
test "Vector int from lower" {
    const vec2 = Vec2i.new(321, 123);
    const vec3 = Vec3i.fromVec2(vec2, 333);
    const vec4 = Vec4i.fromVec3(vec3, 444);

    try testing.expectEqual(Vec3i.new(321, 123, 333), vec3);
    try testing.expectEqual(Vec4i.new(321, 123, 333, 444), vec4);
}

test "Vector int length" {
    const v2 = Vec2i.new(3, 4);
    const v3 = Vec3i.new(3, 4, -2);
    const v4 = Vec4i.new(3, 4, -2, 1);

    try testing.expectEqual(5, v2.length());
    try testing.expectApproxEqRel(@sqrt(29.0), v3.length(), std.math.floatEps(f32));
    try testing.expectApproxEqRel(@sqrt(30.0), v4.length(), std.math.floatEps(f32));
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
    try testing.expectApproxEqRel(std.math.pi/4.0, Vec2i.one.angle(), std.math.floatEps(f32));
}

test "Vector int angle to" {
    try testing.expectApproxEqRel(-std.math.pi/4.0, Vec2i.one.angleTo(Vec2i.right), std.math.floatEps(f32));
    try testing.expectApproxEqRel(std.math.pi/4.0, Vec3i.new(1,1,0).angleTo(Vec3i.right), std.math.floatEps(f32));
}
