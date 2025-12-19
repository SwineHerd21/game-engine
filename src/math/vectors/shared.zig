const std = @import("std");

const assert = std.debug.assert;
const comptimePrint = std.fmt.comptimePrint;
// using std.meta.fieldNames complains about the names not being comptime resolvable for some reason
const fields = std.meta.fields;

const VecN = @import("../math.zig").Vec;

// Somewhat inspired by mach, zlm and Godot

pub fn Shared(Vec: type, T: type, dimensions: comptime_int) type {
    assert(@typeInfo(T) == .int or @typeInfo(T) == .float);
    return extern struct {
        const V = @Vector(dimensions, T);

        /// Cast into a SIMD compatable `@Vector(dim, T)`
        pub inline fn simd(v: Vec) @Vector(dimensions, T) {
            return @bitCast(v);
        }
        /// Cast from a SIMD compatable `@Vector(dim, T)`
        pub inline fn fromSimd(v: @Vector(dimensions, T)) Vec {
            return @bitCast(v);
        }

        /// Returns a vector with all elements set to `value`
        pub fn splat(value: T) Vec {
            return fromSimd(@splat(value));
        }

        /// Get component number `i`: 0 gives `x`, 1 gives `y` etc.
        /// `i` must be less than the vectors dimensions
        pub fn at(v: Vec, i: comptime_int) Vec {
            if (i < 0 or i >= dimensions) @compileError("Vec field out of bounds access");
            const arr: [dimensions]T = @bitCast(v);
            return arr[i];
        }

        // TODO: add safe op versions for integer vecs? (wrapped, saturating, etc.)

        /// Element-wise negation
        pub inline fn neg(v: Vec) Vec {
            return fromSimd(-simd(v));
        }

        /// Element-wise absolute value taking
        pub inline fn abs(v: Vec) Vec {
            return fromSimd(@intCast(@abs(simd(v))));
        }

        /// Element-wise addition
        pub inline fn add(a: Vec, b: Vec) Vec {
            return fromSimd(simd(a) + simd(b));
        }

        /// Element-wise subtraction
        pub inline fn sub(a: Vec, b: Vec) Vec {
            return fromSimd(simd(a) - simd(b));
        }

        /// Element-wise multiplication
        pub inline fn scale(a: Vec, b: Vec) Vec {
            return fromSimd(simd(a) * simd(b));
        }

        /// Element-wise multiplication by a scalar
        pub inline fn mul(a: Vec, scalar: T) Vec {
            return fromSimd(simd(a) * @as(V, @splat(scalar)));
        }

        /// Element-wise division by a scalar
        pub inline fn div(a: Vec, scalar: T) Vec {
            return fromSimd(simd(a) / @as(V, @splat(scalar)));
        }

        /// Element-wise division by a scalar, rounded towards zero
        ///
        /// See `@divTrunc` builtin function for caller guarantees
        pub inline fn divTrunc(a: Vec, scalar: T) Vec {
            return fromSimd(@divTrunc(simd(a), @as(V, @splat(scalar))));
        }

        /// Dot (scalar) product of two vectors
        pub inline fn dot(a: Vec, b: Vec) T {
            return @reduce(.Add, simd(a) * simd(b));
        }

        pub inline fn length(v: Vec) T {
            return @sqrt(@reduce(.Add, simd(v) * simd(v)));
        }
        /// Faster than `length()`
        pub inline fn lengthSqr(v: Vec) T {
            return @reduce(.Add, simd(v) * simd(v));
        }

        pub inline fn distance(a: Vec, b: Vec) T {
            return b.sub(a).length();
        }
        /// Faster than `distance()`
        pub inline fn distanceSqr(a: Vec, b: Vec) T {
            return b.sub(a).lengthSqr();
        }

        /// Returns a vector pointing in the same direction but with length 1
        pub inline fn normalized(v: Vec) Vec {
            return v.mul(@floatCast(1.0 / v.length()));
        }

        /// Linearly interpolate between two vectors by `t`.
        ///
        /// `t` is clamped to [[0,1]]
        ///
        /// When `t` = `0` return `a`
        /// When `t` = `0.5` return midpoint of `a` and `b`
        /// When `t` = `1` return `b`
        pub fn lerp(a: Vec, b: Vec, t: f32) Vec {
            const tc = std.math.clamp(t, 0, 1);
            return a.mul(1 - tc).add(b.mul(tc));
        }

        /// Move from `a` to `b` by a distance of `delta`.
        ///
        /// Will not go further than `b`.
        pub fn moveToward(a: Vec, b: Vec, delta: T) Vec {
            const dir = b.sub(a);
            const len = dir.length();
            return if (len <= delta or len < std.math.floatEps(T)) b else a.add(dir.mul(@floatCast(delta / len)));
        }

        /// Reflect the vector off a surface defined by the normal.
        pub inline fn reflect(v: Vec, normal: Vec) Vec {
            return v.sub(normal.mul(2 * v.dot(normal)));
        }

        /// Returns a vector pointing in the same direction but with length <= `len`
        pub fn clampLength(v: Vec, len: T) Vec {
            const l = v.length();
            if (len < 0 or len >= l) return v;
            return v.mul(@floatCast(len / l));
        }

        /// Checks if two vectors are exactly equal
        pub fn eql(a: Vec, b: Vec) bool {
            // comparing vectors return a bool vector with a value for each element pair
            return @reduce(.And, simd(a) == simd(b));
        }

        /// Checks if two vectors are approximately equal
        /// For values around zero use `approxEqlAbs`
        pub fn approxEqlRel(a: Vec, b: Vec) bool {
            inline for (fields(Vec)) |f| {
                if (!std.math.approxEqRel(T, @field(a, f.name), @field(b, f.name), std.math.floatEps(T))) return false;
            }
            return true;
        }
        /// Checks if two vectors are approximately equal
        /// This function is useful around zero, use `approxEqlRel` in other cases
        pub fn approxEqlAbs(a: Vec, b: Vec) bool {
            inline for (fields(Vec)) |f| {
                if (!std.math.approxEqAbs(T, @field(a, f.name), @field(b, f.name), 5*std.math.floatEps(T))) return false;
            }
            return true;
        }

        /// Should be called from a proper format method
        pub fn format(v: Vec, writer: *std.Io.Writer) std.Io.Writer.Error!void {
            const vec_fields = comptime fields(Vec);
            const fmt = comptime blk: {
                var fmt: []const u8 = "(";
                for (0..vec_fields.len) |i| {
                    fmt = fmt ++ "{}";
                    if (i != vec_fields.len - 1) {
                        fmt = fmt ++ ", ";
                    }
                }
                break :blk fmt ++ ")";
            };

            try writer.print(fmt, v);
        }
    };
}

