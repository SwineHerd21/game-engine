const std = @import("std");

const Vec = @import("../math.zig").Vec;
const MatNxM = @import("../math.zig").MatNxM;

pub fn Shared(T: type, rows: comptime_int, columns: comptime_int) type {
    std.debug.assert(@typeInfo(T) == .float);
    return extern struct {
        const Self = @This();
        const Mat = MatNxM(T, rows, columns);

        /// A matrix with all elements equal to zero
        pub const zero = splat(0);

        /// Create a matrix with all elements equal to `value`
        pub fn splat(value: T) Mat {
            return .{ .data = @splat(.splat(value)) };
        }

        /// Note: elements are supplied in column-major order
        pub fn fromArrays(elements: [columns][rows]T) Mat {
            return @bitCast(elements);
        }

        /// Note: supplied vectors will become matrix columns, not rows
        pub fn fromVecs(vecs: [columns]Mat.ColumnVec) Mat {
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

        const TransposedType: type = MatNxM(T, columns, rows);
        pub fn transposed(m: Mat) TransposedType {
            const m_arr: [columns][rows]T = @bitCast(m);
            var new: [rows][columns]T = undefined;
            inline for (0..rows) |r| {
                inline for (0..columns) |c| {
                    new[r][c] = m_arr[c][r];
                }
            }
            return @bitCast(new);
        }

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
            inline for (0..Mat2.columns) |col| {
                inline for (0..Mat.rows) |row| {
                    var el: T = 0;
                    for (0..Mat2.rows) |k| {
                        el += a_arr[k][col] * b_arr[rows][k];
                    }
                    new[col][row] = el;
                }
            }
            return @bitCast(new);
        }
    };
}
