const std = @import("std");
const assert = std.debug.assert;

const Vec = @import("../math.zig").Vec;
const MatNxM = @import("../math.zig").MatNxM;

pub fn Shared(Mat: type, T: type, rows: comptime_int, columns: comptime_int) type {
    assert(@typeInfo(T) == .float);
    return extern struct {
        const Self = @This();

        /// A matrix with all elements equal to zero
        pub const zero: Mat = splat(0);
        /// A diagonal matrix with elements equal to 1.
        /// Has the property `X * identity = X`
        pub const identity: Mat = blk: {
            assert(rows == columns);
            var id: [columns][rows]T = undefined;
            for (0..columns) |c| {
                for (0..rows) |r| {
                    id[c][r] = @intFromBool(c == r);
                }
            }
            break :blk @bitCast(id);
        };

        /// Create a matrix with all elements equal to `value`
        pub fn splat(value: T) Mat {
            return .{ .data = @splat(.splat(value)) };
        }

        /// Note: elements are supplied in column-major order
        pub fn fromArrays(elements: [Mat.columns][Mat.rows]T) Mat {
            return @bitCast(elements);
        }

        /// Note: supplied vectors will become matrix columns, not rows
        pub fn fromVecs(vecs: [Mat.columns]Mat.ColumnVec) Mat {
            return .{ .data = vecs };
        }

        /// Element-wise negation
        pub fn neg(m: Mat) Mat {
            var new: Mat = undefined;
            inline for (0..columns) |i| {
                new.data[i] = m.data[i].neg();
            }
            return new;
        }

        /// Element-wise addition
        pub fn add(a: Mat, b: Mat) Mat {
            var new: Mat = undefined;
            inline for (0..columns) |i| {
                new.data[i] = a.data[i].add(b.data[i]);
            }
            return new;
        }

        /// Element-wise subtraction
        pub fn sub(a: Mat, b: Mat) Mat {
            var new: Mat = undefined;
            inline for (0..columns) |i| {
                new.data[i] = a.data[i].sub(b.data[i]);
            }
            return new;
        }

        /// Element-wise multiplication by a scalar
        pub fn mulScalar(a: Mat, scalar: T) Mat {
            var new: Mat = undefined;
            inline for (0..columns) |i| {
                new.data[i] = a.data[i].mul(scalar);
            }
            return new;
        }

        /// Element-wise division by a scalar
        pub fn divScalar(a: Mat, scalar: T) Mat {
            var new: Mat = undefined;
            inline for (0..columns) |i| {
                new.data[i] = a.data[i].div(scalar);
            }
            return new;
        }

        /// Switches the rows and columns of the matrix
        pub fn transposed(m: Mat) MatNxM(T, Mat.columns, Mat.rows) {
            const m_arr: [columns][rows]T = @bitCast(m);
            var new: [rows][columns]T = undefined;
            inline for (0..rows) |r| {
                inline for (0..columns) |c| {
                    new[r][c] = m_arr[c][r];
                }
            }
            return @bitCast(new);
        }

        /// Matrix by matrix multiplication. `b` must have the same amount of rows as `a` has columns
        pub fn mul(a: Mat, b: anytype) MatNxM(T, Mat.rows, @TypeOf(b).columns) {
            const Mat2 = @TypeOf(b);
            const errMsg = std.fmt.comptimePrint("Matrix multiplication of {s} by {s} is not supported", .{@typeName(Mat), @typeName(@TypeOf(b))});
            switch (Mat2) {
                MatNxM(T, columns, 2), MatNxM(T, columns, 3), MatNxM(T, columns, 4) => {},
                else => @compileError(errMsg),
            }

            const a_arr: [Mat.columns][Mat.rows]T = @bitCast(a);
            const b_arr: [Mat2.columns][Mat2.rows]T = @bitCast(b);
            var new: [Mat2.columns][Mat.rows]T = undefined;
            inline for (0..Mat2.columns) |c| {
                inline for (0..Mat.rows) |r| {
                    var el: T = 0;
                    for (0..Mat2.rows) |k| {
                        el += a_arr[k][r] * b_arr[c][k];
                    }
                    new[c][r] = el;
                }
            }
            return @bitCast(new);
        }

        /// Multiple many matricies in order
        pub fn mulBatch(matricies: []const Mat) Mat {
            var tr: Mat = matricies[0];
            for (1..matricies.len) |i| {
                tr = tr.mulMatrix(matricies[i]);
            }
            return tr;
        }

        /// Checks if two matricies are exactly equal
        pub fn eql(a: Mat, b: Mat) bool {
            const a_arr: [rows*columns]T = @bitCast(a);
            const b_arr: [rows*columns]T = @bitCast(b);
            return std.mem.eql(T, &a_arr, &b_arr);
        }

        /// Checks if two matricies are approximately equal
        /// For values around zero use `approxEqlAbs`
        pub fn approxEqlRel(a: Mat, b: Mat) bool {
            const a_arr: [rows*columns]T = @bitCast(a);
            const b_arr: [rows*columns]T = @bitCast(b);
            inline for (0..(rows*columns)) |i| {
                if (!std.math.approxEqRel(T, a_arr[i], b_arr[i], std.math.floatEps(T))) return false;
            }
            return true;
        }

        /// Checks if two matricies are approximately equal
        /// This function is useful around zero, use `approxEqlRel` in other cases
        pub fn approxEqlAbs(a: Mat, b: Mat) bool {
            const a_arr: [rows*columns]T = @bitCast(a);
            const b_arr: [rows*columns]T = @bitCast(b);
            inline for (0..(rows*columns)) |i| {
                if (!std.math.approxEqAbs(T, a_arr[i], b_arr[i], 5*std.math.floatEps(T))) return false;
            }
            return true;
        }
    };
}
