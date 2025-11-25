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

        const funcs = Shared(Self, T, rows, columns);
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
        pub const mulBatch = funcs.mulBatch;
        pub const transposed = funcs.transposed;
        pub const eql = funcs.eql;
        pub const approxEqlRel = funcs.approxEqlRel;
        pub const approxEqlAbs = funcs.approxEqlAbs;
    };
}

// ========== Testing ==========

const testing = std.testing;
const math = @import("../math.zig");

test "Matrix splat" {
    const mat = math.Mat2x3.splat(2.0);
    try testing.expectEqual([_]f32{2.0} ** 6, @as([6]f32, @bitCast(mat)));

    const mat2 = math.Mat3x2.splat(2.3);
    try testing.expectEqual([_]f32{2.3} ** 6, @as([6]f32, @bitCast(mat2)));
}

test "Matrix add" {
    const mat = math.Mat2x3.splat(2.0);
    const mat2 = math.Mat2x3.splat(1.2);
    try testing.expectEqual(math.Mat2x3.splat(3.2), mat.add(mat2));
}

test "Matrix sub" {
    const mat = math.Mat2x3.splat(2.0);
    const mat2 = math.Mat2x3.splat(1.5);
    try testing.expectEqual(math.Mat2x3.splat(0.5), mat.sub(mat2));
}

test "Matrix neg" {
    const mat = math.Mat2x3.splat(2.0);
    try testing.expectEqual(math.Mat2x3.splat(-2.0), mat.neg());
}

test "Matrix mulScalar" {
    const mat = math.Mat2x3.splat(2.0);
    try testing.expectEqual(math.Mat2x3.splat(4.0), mat.mulScalar(2.0));
}

test "Matrix divScalar" {
    const mat = math.Mat2x3.splat(2.0);
    try testing.expectEqual(math.Mat2x3.splat(1.0), mat.divScalar(2.0));
}

test "Matrix mul type check" {
    const mat = math.Mat2x3.splat(2.0);
    const mat2 = math.Mat3x2.splat(2.0);

    const res = mat.mul(mat2);
    const res2 = mat2.mul(mat);

    try testing.expect(@TypeOf(res) == math.Mat2);
    try testing.expect(res.approxEqlRel(math.Mat2.splat(12.0)));

    try testing.expect(@TypeOf(res2) == math.Mat3);
    try testing.expect(res2.approxEqlRel(math.Mat3.splat(8.0)));
}

test "Matrix mul value check" {
    // [1 2]
    // [2 1]
    const a = math.Mat2.fromVecs(.{
        .new(1, 2),
        .new(2, 1)
    });
    // [1 2 3]
    // [4 5 6]
    const b = math.Mat2x3.fromVecs(.{
        .new(1, 4),
        .new(2, 5),
        .new(3, 6),
    });

    // [9 12 15]
    // [6 9 12]
    const res = math.Mat2x3.fromVecs(.{
        .new(9, 6),
        .new(12, 9),
        .new(15, 12),
    });

    try testing.expectEqual(res, a.mul(b));
}

test "Matrix transposed" {
    const mat = math.Mat2x3.splat(2.0);
    const mat2 = math.Mat3x2.splat(2.0);

    try testing.expectEqual(mat2, mat.transposed());
}
