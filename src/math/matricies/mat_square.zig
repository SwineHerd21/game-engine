const std = @import("std");
const assert = std.debug.assert;
const maxInt = std.math.maxInt;

const Shared = @import("shared.zig").Shared;
const Vec = @import("../math.zig").Vec;

/// Gives a square column-major matrix of `T`
/// `T` must be a float
/// Contains `columns` of `Vec(T, rows)`
pub fn Mat2x2(T: type) type {
    assert(@typeInfo(T) == .float);
    return extern struct {
        const Self = @This();
        pub const ColumnVec = Vec(T, rows);

        pub const rows: usize = 2;
        pub const columns: usize = 2;

        /// Consists of `Vec` columns
        data: [columns]ColumnVec,

        const funcs = Shared(T, rows, columns);
        pub const zero = funcs.zero;
        pub const unit: Self = Self.fromArrays(.{
            .{1, 0},
            .{0, 1}
        });

        pub const splat = funcs.splat;
        pub const fromArrays = funcs.fromArrays;
        pub const fromVecs = funcs.fromVecs;
        pub const neg = funcs.neg;
        pub const add = funcs.add;
        pub const sub = funcs.sub;
        pub const mulScalar = funcs.mulScalar;
        pub const divScalar = funcs.divScalar;
        pub const mul = funcs.mul;
        pub const transposed = funcs.transposed;

        pub fn determinant(m: Self) T {
            const arr: [4]T = @bitCast(m);
            return arr[0]*arr[3] - arr[1]*arr[2];
        }

        /// Calculate the inverse matrix. If it does not exist returns `null`
        pub fn inverse(m: Self) ?Self {
            const det = m.determinant();
            if (std.math.approxEqAbs(T, det, 0, 1e-8)) return null;

            const arr: [4]T = @bitCast(m);
            const data = @as([columns]ColumnVec, @bitCast([4]T{arr[3], -arr[2], -arr[1], arr[0]}));
            return (Self{ .data = data }).divScalar(det);
        }
    };
}
