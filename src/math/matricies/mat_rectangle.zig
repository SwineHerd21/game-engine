const std = @import("std");
const assert = std.debug.assert;
const maxInt = std.math.maxInt;

const Shared = @import("shared.zig").Shared;
const Vec = @import("../math.zig").Vec;

/// Gives a rectangular column-major matrix of `T`
/// `T` must be a float
/// Contains `columns` of `Vec(T, rows)`
pub fn MatRectangle(T: type, _rows: comptime_int, _columns: comptime_int) type {
    assert(@typeInfo(T) == .float);
    assert(_columns > 0 and _rows >= 2 and _columns <= maxInt(usize) and _rows <= 4);
    if (_columns == _rows) @compileError("Please use `MatSquare` for square matricies");

    return extern struct {
        const Self = @This();
        pub const ColumnVec = Vec(T, rows);

        pub const rows: usize = _rows;
        pub const columns: usize = _columns;

        /// Consists of `Vec` columns
        data: [columns]ColumnVec,

        const funcs = Shared(T, rows, columns);
        pub const zero = funcs.zero;

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
    };
}

// ========== Testing ==========

const testing = std.testing;
const Mat2 = @import("mat_square.zig").Mat2x2;

test "Matrix splat" {
    const mat = MatRectangle(f32, 2, 3).splat(2.0);
    try testing.expectEqual([_]f32{2.0} ** 6, @as([6]f32, @bitCast(mat)));

    const mat2 = MatRectangle(f32, 3, 2).splat(2.3);
    try testing.expectEqual([_]f32{2.3} ** 6, @as([6]f32, @bitCast(mat2)));
}

test "Matrix add" {
    const mat = MatRectangle(f32, 2, 3).splat(2.0);
    const mat2 = MatRectangle(f32, 2, 3).splat(1.2);
    try testing.expectEqual([_]f32{3.2} ** 6, @as([6]f32, @bitCast(mat.add(mat2))));
}

test "Matrix sub" {
    const mat = MatRectangle(f32, 2, 3).splat(2.0);
    const mat2 = MatRectangle(f32, 2, 3).splat(1.2);
    try testing.expectEqual([_]f32{0.8} ** 6, @as([6]f32, @bitCast(mat.sub(mat2))));
}

test "Matrix neg" {
    const mat = MatRectangle(f32, 2, 3).splat(2.0);
    try testing.expectEqual([_]f32{-2.0} ** 6, @as([6]f32, @bitCast(mat.neg())));
}

test "Matrix mulScalar" {
    const mat = MatRectangle(f32, 2, 3).splat(2.0);
    try testing.expectEqual([_]f32{4.0} ** 6, @as([6]f32, @bitCast(mat.mulScalar(2.0))));
}

test "Matrix divScalar" {
    const mat = MatRectangle(f32, 2, 3).splat(2.0);
    try testing.expectEqual([_]f32{1.0} ** 6, @as([6]f32, @bitCast(mat.divScalar(2.0))));
}

test "Matrix mul" {
    const mat = MatRectangle(f32, 2, 3).splat(2.0);
    const mat2 = MatRectangle(f32, 3, 2).splat(2.0);

    const res = Mat2(f32).splat(12.0);

    try testing.expectEqualDeep(res, mat.mul(mat2));
}

test "Matrix transposed" {
    const mat = MatRectangle(f32, 2, 3).splat(2.0);
    const mat2 = MatRectangle(f32, 3, 2).splat(2.0);

    try testing.expectEqual(mat2, mat.transposed());
}
