const std = @import("std");

const assert = std.debug.assert;
const comptimePrint = std.fmt.comptimePrint;
// using std.meta.fieldNames complains about the names not being comptime resolvable for some reason
const fields = std.meta.fields;

// Somewhat inspired by mach, zlm and Godot

pub fn Shared(Vec: type, T: type) type {
    assert(@typeInfo(T) == .int or @typeInfo(T) == .float);
    return extern struct {
        /// Returns a vector with all elements set to `value`
        pub fn splat(value: T) Vec {
            var new: Vec = undefined;
            inline for (fields(Vec)) |f| {
                @field(new, f.name) = value;
            }
            return new;
        }

        // TODO: add safe op versions for integer vecs? (wrapped, saturating, etc.)

        /// Element-wise negation
        pub fn neg(v: Vec) Vec {
            var new: Vec = undefined;
            inline for (fields(Vec)) |f| {
                @field(new, f.name) = -@field(v, f.name);
            }
            return new;
        }

        /// Element-wise absolute value taking
        pub fn abs(v: Vec) Vec {
            var new: Vec = undefined;
            inline for (fields(Vec)) |f| {
                @field(new, f.name) = if (@typeInfo(T) == .int) @intCast(@abs(@field(v, f.name))) else @abs(@field(v, f.name));
            }
            return new;
        }

        /// Element-wise addition
        pub fn add(a: Vec, b: Vec) Vec {
            var new: Vec = undefined;
            inline for (fields(Vec)) |f| {
                @field(new, f.name) = @field(a, f.name) + @field(b, f.name);
            }
            return new;
        }

        /// Element-wise subtraction
        pub fn sub(a: Vec, b: Vec) Vec {
            var new: Vec = undefined;
            inline for (fields(Vec)) |f| {
                @field(new, f.name) = @field(a, f.name) - @field(b, f.name);
            }
            return new;
        }

        /// Element-wise multiplication
        pub fn scale(a: Vec, b: Vec) Vec {
            var new: Vec = undefined;
            inline for (fields(Vec)) |f| {
                @field(new, f.name) = @field(a, f.name) * @field(b, f.name);
            }
            return new;
        }

        /// Element-wise multiplication by a scalar
        pub fn mul(a: Vec, scalar: T) Vec {
            var new: Vec = undefined;
            inline for (fields(Vec)) |f| {
                @field(new, f.name) = @field(a, f.name) * scalar;
            }
            return new;
        }

        /// Element-wise division by a scalar
        pub fn div(a: Vec, scalar: T) Vec {
            var new: Vec = undefined;
            inline for (fields(Vec)) |f| {
                @field(new, f.name) = @field(a, f.name) / scalar;
            }
            return new;
        }

        /// Element-wise division by a scalar, rounded towards zero
        ///
        /// See `@divTrunc` builtin function for caller guarantees
        pub fn divTrunc(a: Vec, scalar: T) Vec {
            var new: Vec = undefined;
            inline for (fields(Vec)) |f| {
                @field(new, f.name) = @divTrunc(@field(a, f.name), scalar);
            }
            return new;
        }

        /// Dot (scalar) product of two vectors
        pub fn dot(a: Vec, b: Vec) T {
            var result: T = 0;
            inline for (fields(Vec)) |f| {
                result += @field(a, f.name) * @field(b, f.name);
            }
            return result;
        }

        pub fn length(v: Vec) T {
            var result: T = 0;
            inline for (fields(Vec)) |f| {
                result += @field(v, f.name) * @field(v, f.name);
            }
            return @sqrt(result);
        }
        /// Faster than `length()`
        pub fn lengthSqr(v: Vec) T {
            var result: T = 0;
            inline for (fields(Vec)) |f| {
                result += @field(v, f.name) * @field(v, f.name);
            }
            return result;
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
            return v.div(@floatCast(v.length()));
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
            inline for (fields(Vec)) |f| {
                if (@field(a, f.name) != @field(b, f.name)) return false;
            }
            return true;
        }

        /// Checks if two vectors are approximately equal
        pub fn approxEql(a: Vec, b: Vec) bool {
            inline for (fields(Vec)) |f| {
                if (!std.math.approxEqRel(T, @field(a, f.name), @field(b, f.name), std.math.floatEps(T))) return false;
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

