//! Floating point mathematical vectors

const std = @import("std");

// Somewhat stolen from mach and Godot

/// A vector with 2 elements of f32
pub const Vec2f = extern struct {
    const Vec = @This();
    const N = 2;
    const T = f32;

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
    pub inline fn cross(a: Vec, b: Vec) f32 {
        return a.x()*b.y() - a.y()*b.x();
    }

    /// Returns the angle between the vector and the positive X axis.
    ///
    /// See `angle_to()` for angle between vectors
    pub inline fn angle(v: Vec) f32 {
        return std.math.atan2(v.x(), v.y());
    }

    /// Find the angle between two vectors.
    pub inline fn angleTo(a: Vec, b: Vec) f32 {
        return std.math.atan2(a.cross(b), a.dot(b));
    }

    const funcs = Shared(Vec, N, T);
    pub const splat = funcs.splat;
    pub const negate = funcs.negate;
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
    pub const eqlApprox = funcs.eqlApprox;

    pub fn format(
        self: @This(),
        writer: *std.Io.Writer,
    ) std.Io.Writer.Error!void {
        try writer.print("({}, {})", .{self.x(), self.y()});
    }
};

/// A vector with 3 elements of f32
pub const Vec3f = extern struct {
    const Vec = @This();
    const N = 3;
    const T = f32;

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
    pub inline fn fromVec2(v: Vec2f, _z: T) Vec {
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
        return std.math.atan2(a.cross(b).length(), a.dot(b));
    }

    const funcs = Shared(Vec, N, T);
    pub const splat = funcs.splat;
    pub const negate = funcs.negate;
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
    pub const eqlApprox = funcs.eqlApprox;

    pub fn format(
        self: @This(),
        writer: *std.Io.Writer,
    ) std.Io.Writer.Error!void {
        try writer.print("({}, {}, {})", .{self.x(), self.y(), self.z()});
    }
};

/// A vector with 4 elements of f32
pub const Vec4f = extern struct {
    const Vec = @This();
    const N = 4;
    const T = f32;

    v: [N]T,

    pub const zero: Vec = .splat(0);
    pub const one: Vec = .splat(1);

    pub inline fn new(_x: T, _y: T, _z: T, _w: T) Vec {
        return .{ .v = .{_x,_y,_z,_w} };
    }
    pub inline fn fromVec3(v: Vec3f, _w: T) Vec {
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
    pub const splat = funcs.splat;
    pub const negate = funcs.negate;
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
    pub const eqlApprox = funcs.eqlApprox;

    pub fn format(
        self: @This(),
        writer: *std.Io.Writer,
    ) std.Io.Writer.Error!void {
        try writer.print("({}, {}, {}, {})", .{self.x(), self.y(), self.z(), self.w()});
    }
};

pub fn Shared(Vec: type, N: comptime_int, T: type) type {
    std.debug.assert(@hasField(Vec, "v") and @FieldType(Vec, "v") == [N]T);
    return extern struct {
        /// Returns a vector with all elements set to `value`
        pub inline fn splat(value: T) Vec {
            return .{.v = @splat(value)};
        }

        /// Element-wise negation
        pub inline fn negate(v: Vec) Vec {
            var new: [N]T = undefined;
            inline for (0..N) |i| {
                new[i] = -v.v[i];
            }
            return .{.v = new};
        }

        /// Element-wise addition
        pub inline fn add(a: Vec, b: Vec) Vec {
            var new: [N]T = undefined;
            inline for (0..N) |i| {
                new[i] = a.v[i] + b.v[i];
            }
            return .{.v = new};
        }

        /// Element-wise subtraction
        pub inline fn sub(a: Vec, b: Vec) Vec {
            var new: [N]T = undefined;
            inline for (0..N) |i| {
                new[i] = a.v[i] - b.v[i];
            }
            return .{.v = new};
        }

        /// Element-wise multiplication
        pub inline fn scale(a: Vec, b: Vec) Vec {
            var new: [N]T = undefined;
            inline for (0..N) |i| {
                new[i] = a.v[i] * b.v[i];
            }
            return .{.v = new};
        }

        /// Element-wise multiplication by a scalar
        pub inline fn mul(a: Vec, scalar: T) Vec {
            var new: [N]T = undefined;
            inline for (0..N) |i| {
                new[i] = a.v[i] * scalar;
            }
            return .{.v = new};
        }

        /// Element-wise division by a scalar
        pub inline fn div(a: Vec, scalar: T) Vec {
            var new: [N]T = undefined;
            inline for (0..N) |i| {
                new[i] = a.v[i] / scalar;
            }
            return .{.v = new};
        }

        /// Dot (scalar) product of two vectors
        pub inline fn dot(a: Vec, b: Vec) T {
            var result: T = 0;
            inline for (0..N) |i| {
                result += a.v[i]*b.v[i];
            }
            return result;
        }

        pub inline fn length(v: Vec) f32 {
            var result: T = 0;
            inline for (0..N) |i| {
                result += v.v[i]*v.v[i];
            }
            return @sqrt(@as(f32, result));
        }
        /// Faster than `length()`
        pub inline fn lengthSqr(v: Vec) T {
            var result: T = 0;
            inline for (0..N) |i| {
                result += v.v[i]*v.v[i];
            }
            return result;
        }

        pub inline fn distance(a: Vec, b: Vec) f32 {
            return b.sub(a).length();
        }
        /// Faster than `distance()`
        pub inline fn distanceSqr(a: Vec, b: Vec) T {
            return b.sub(a).lengthSqr();
        }

        /// Returns a vector pointing in the same direction but with length 1
        pub inline fn normalized(v: Vec) Vec {
            return v.div(v.length());
        }

        /// Linearly interpolate between two vectors by `t`.
        ///
        /// `t` is clamped to [[0,1]]
        ///
        /// When `t` = `0` return `a`
        /// When `t` = `0.5` return midpoint of `a` and `b`
        /// When `t` = `1` return `b`
        pub inline fn lerp(a: Vec, b: Vec, t: f32) Vec {
            const tc = std.math.clamp(t, 0, 1);
            return a.mul(1 - tc).add(b.mul(tc));
        }

        /// Move from `a` to `b` by a distance of `delta`.
        ///
        /// Will not go further than `b`.
        pub inline fn moveToward(a: Vec, b: Vec, delta: f32) Vec {
            const dir = b.sub(a);
            const len = dir.length();
            return if (len <= delta or len < std.math.floatEps(f32)) b else a.add(dir.mul(delta / len));
        }

        /// Reflect the vector off a surface defined by the normal.
        pub inline fn reflect(v: Vec, normal: Vec) Vec {
            return v.sub(normal.mul(2 * v.dot(normal)));
        }

        /// Returns a vector pointing in the same direction but with length <= `len`
        pub inline fn clampLength(v: Vec, len: f32) Vec {
            const l = v.length();
            if (len < 0 or len >= l) return v;
            return v.mul(len / l);
        }

        /// Checks if two vectors are exactly equal
        pub inline fn eql(a: Vec, b: Vec) bool {
            inline for (0..N) |i| {
                if (a.v[i] != b.v[i]) return false;
            }
            return true;
        }

        /// Checks if two vectors are approximately equal
        pub inline fn eqlApprox(a: Vec, b: Vec) bool {
            inline for (0..N) |i| {
                if (!std.math.approxEqRel(T, a.v[i], b.v[i], std.math.floatEps(T))) return false;
            }
            return true;
        }
    };
}

// ========== Tests ==========

const testing = std.testing;

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
    try testing.expectEqual(Vec3f.new(18.5, 46, 42).negate(), Vec3f.new(8, 5, -9).cross(Vec3f.new(2, -4, 3.5)));
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

    try testing.expect(Vec2f.new(4.0/5.0, 3.0/5.0).eqlApprox(Vec2f.new(4, 3).normalized()));
    try testing.expect(Vec3f.new(4.0/@sqrt(41.0), 3.0/@sqrt(41.0), 4.0/@sqrt(41.0)).eqlApprox(Vec3f.new(4, 3, 4).normalized()));
    try testing.expect(Vec4f.new(1.0/2.0,3.0/8.0,1.0/2.0,@sqrt(23.0)/8.0).eqlApprox(Vec4f.new(4, 3, 4, @sqrt(23.0)).normalized()));
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

