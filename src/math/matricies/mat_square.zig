const std = @import("std");
const assert = std.debug.assert;
const maxInt = std.math.maxInt;

const Shared = @import("shared.zig").Shared;
const Vec = @import("../math.zig").Vec;

/// Gives a 2x2 column-major matrix of `T`
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

        const funcs = Shared(Self, T, rows, columns);
        pub const zero = funcs.zero;
        pub const identity: Self = Self.fromArrays(.{
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
        pub const mulBatch = funcs.mulBatch;
        pub const transposed = funcs.transposed;
        pub const eql = funcs.eql;
        pub const approxEqlRel = funcs.approxEqlRel;
        pub const approxEqlAbs = funcs.approxEqlAbs;

        pub inline fn determinant(m: Self) T {
            const arr: [columns*rows]T = @bitCast(m);
            // [0 2]
            // [1 3]
            return arr[0]*arr[3] - arr[1]*arr[2];
        }

        /// Calculate the inverse matrix. If it does not exist returns `null`
        pub fn inverse(m: Self) ?Self {
            const det = m.determinant();
            if (std.math.approxEqAbs(T, det, 0, 0.01 * std.math.floatEps(T))) return null;

            const arr: [columns * rows]T = @bitCast(m);
            const data = @as([columns]ColumnVec, @bitCast([columns*rows]T{arr[3], -arr[2], -arr[1], arr[0]}));
            return (Self{ .data = data }).mulScalar(1.0 / det);
        }
    };
}

/// Gives a 3x3 column-major matrix of `T`
/// `T` must be a float
/// Contains `columns` of `Vec(T, rows)`
pub fn Mat3x3(T: type) type {
    assert(@typeInfo(T) == .float);
    return extern struct {
        const Self = @This();
        pub const ColumnVec = Vec(T, rows);

        pub const rows: usize = 3;
        pub const columns: usize = 3;

        /// Consists of `Vec` columns
        data: [columns]ColumnVec,

        const funcs = Shared(Self, T, rows, columns);
        pub const zero = funcs.zero;
        pub const identity = funcs.identity;

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

        pub inline fn determinant(m: Self) T {
            // [0 3 6]
            // [1 4 7]
            // [2 5 8]
            const arr: [columns*rows]T = @bitCast(m);
            return arr[0]*(arr[4]*arr[8] - arr[5]*arr[7])
                 + arr[1]*(arr[5]*arr[6] - arr[3]*arr[8])
                 + arr[2]*(arr[3]*arr[7] - arr[4]*arr[6]);
        }

        /// Calculate the inverse matrix. If it does not exist returns `null`
        pub fn inverse(m: Self) ?Self {
            const det = m.determinant();
            if (std.math.approxEqAbs(T, det, 0, 3*std.math.floatEps(T))) return null;

            const arr: [columns][rows]T = @bitCast(m);
            var inv: [columns][rows]T = undefined;

            // [00 10 20]
            // [01 11 21]
            // [02 12 22]
            // Обратная матрица это транспозированная матрица алгебраических дополнений
            inv[0][0] =  (arr[1][1]*arr[2][2] - arr[1][2]*arr[2][1]);
            inv[0][1] = -(arr[0][1]*arr[2][2] - arr[0][2]*arr[2][1]);
            inv[0][2] =  (arr[0][1]*arr[1][2] - arr[0][2]*arr[1][1]);
            inv[1][0] = -(arr[1][0]*arr[2][2] - arr[1][2]*arr[2][0]);
            inv[1][1] =  (arr[0][0]*arr[2][2] - arr[0][2]*arr[2][0]);
            inv[1][2] = -(arr[0][0]*arr[1][2] - arr[0][2]*arr[1][0]);
            inv[2][0] =  (arr[1][0]*arr[2][1] - arr[1][1]*arr[2][0]);
            inv[2][1] = -(arr[0][0]*arr[2][1] - arr[0][1]*arr[2][0]);
            inv[2][2] =  (arr[0][0]*arr[1][1] - arr[0][1]*arr[1][0]);

            return @as(Self, @bitCast(inv)).mulScalar(1.0 / det);
        }
    };
}

/// Gives a 4x4 column-major matrix of `T`
/// `T` must be a float
/// Contains `columns` of `Vec(T, rows)`
pub fn Mat4x4(T: type) type {
    assert(@typeInfo(T) == .float);
    return extern struct {
        const Self = @This();
        pub const ColumnVec = Vec(T, rows);

        pub const rows: usize = 4;
        pub const columns: usize = 4;

        /// Consists of `Vec` columns
        data: [columns]ColumnVec,

        const funcs = Shared(Self, T, rows, columns);
        pub const zero = funcs.zero;
        pub const identity = funcs.identity;

        pub const splat = funcs.splat;
        pub const fromArrays = funcs.fromArrays;
        pub const fromVecs = funcs.fromVecs;
        pub const neg = funcs.neg;
        pub const add = funcs.add;
        pub const sub = funcs.sub;
        pub const mulScalar = funcs.mulScalar;
        pub const divScalar = funcs.divScalar;
        pub const mulMatrix = funcs.mul;
        pub const mulBatch = funcs.mulBatch;
        pub const transposed = funcs.transposed;
        pub const eql = funcs.eql;
        pub const approxEqlRel = funcs.approxEqlRel;
        pub const approxEqlAbs = funcs.approxEqlAbs;

        pub fn determinant(m: Self) T {
            const arr: [columns*rows]T = @bitCast(m);
            _ = arr;
            // TODO
            return 606;
        }

        /// Calculate the inverse matrix. If it does not exist returns `null`
        pub fn inverse(m: Self) ?Self {
            const det = m.determinant();
            if (std.math.approxEqAbs(T, det, 0, 3*std.math.floatEps(T))) return null;

            const arr: [columns][rows]T = @bitCast(m);
            var inv: [columns][rows]T = undefined;

            inv = @bitCast(zero);
            _ = arr;

            // TODO

            return @as(Self, @bitCast(inv)).mulScalar(1.0 / det);
        }

        // TODO: useful functions (transforms, projections, ...)

        pub fn mulVec(a: Self, b: Vec(T, 4)) @TypeOf(b) {
            var new: ColumnVec = undefined;
            inline for (@typeInfo(ColumnVec).@"struct".fields, 0..) |f, i| {
                new = new.add(a.data[i].mul(@field(b, f.name)));
            }
            return new;
        }

        /// Make a scaling matrix
        pub inline fn scaling(x: T, y: T, z: T) Self {
            return fromArrays(.{
                .{x,0,0,0},
                .{0,y,0,0},
                .{0,0,z,0},
                .{0,0,0,1},
            });
        }

        /// Make a translation matrix
        pub inline fn translation(x: T, y: T, z: T) Self {
            return fromArrays(.{
                .{1,0,0,0},
                .{0,1,0,0},
                .{0,0,1,0},
                .{x,y,z,1},
            });
        }

        /// Make a rotation matrix around an arbitrary axis
        pub fn rotation(axis: Vec(T, 3), angle: T) Self {
            const sin = @sin(angle);
            const cos = @cos(angle);
            const n = axis.normalized();
            const t = n.mul(1-cos);

            return Self.fromArrays(.{
                .{cos + n.x*t.x, n.y*t.x + n.z*sin, n.z*t.x - n.y*sin, 0},
                .{n.x*t.y - n.z*sin, cos + n.y*t.y, n.z*t.y + n.x*sin, 0},
                .{n.x*t.z + n.y*sin, n.y*t.z - n.x*sin, cos + n.z*t.z, 0},
                .{0, 0, 0, 1},
            });
        }

        /// Make a rotation matrix around the X axis
        pub inline fn rotationX(angle: T) Self {
            return fromArrays(.{
                .{1,0,0,0},
                .{0, @cos(angle), @sin(angle), 0},
                .{0, -@sin(angle), @cos(angle), 0},
                .{0,0,0,1},
            });
        }
        /// Make a rotation matrix around the Y axis
        pub inline fn rotationY(angle: T) Self {
            return fromArrays(.{
                .{@cos(angle), 0, -@sin(angle), 0},
                .{0,1,0,0},
                .{@sin(angle), 0, @cos(angle), 0},
                .{0,0,0,1},
            });
        }
        /// Make a rotation matrix around the Z axis
        pub inline fn rotationZ(angle: T) Self {
            return fromArrays(.{
                .{@cos(angle), @sin(angle), 0, 0},
                .{-@sin(angle), @cos(angle), 0, 0},
                .{0,0,1,0},
                .{0,0,0,1},
            });
        }

        /// Make a perspective projection matrix based on horizontal FOV and aspect ratio
        pub fn perspective(fov: T, aspectRatio: T, clip_near: T, clip_far: T) Self {
            // https://songho.ca/opengl/gl_projectionmatrix.html
            const tan = @tan(std.math.degreesToRadians(fov/2));
            const right = clip_near * tan;
            const top = right / aspectRatio;

            return Self.fromArrays(.{
                .{clip_near/right, 0, 0, 0},
                .{0, clip_near/top, 0, 0},
                .{0, 0, -(clip_far+clip_near)/(clip_far-clip_near), -1},
                .{0, 0, -2*clip_far*clip_near/(clip_far-clip_near), 0},
            });
        }

        /// Make an orthographic projection matrix based on horizontal FOV and aspect ratio
        pub fn orthographic(width: T, height: T, clip_near: T, clip_far: T) Self {
            // https://songho.ca/opengl/gl_projectionmatrix.html
            const right = width/2;
            const top = height/2;
            return Self.fromArrays(.{
                .{1/right, 0, 0, 0},
                .{0, 1/top, 0, 0},
                .{0, 0, -2/(clip_far-clip_near), 0},
                .{0, 0, 0, 1},
            });
        }
    };
}

// ========== Testing ==========
const testing = std.testing;

test "Matrix identity" {
    try testing.expectEqual(Mat2x2(f32).fromArrays(.{
        .{1,0},
        .{0,1},
    }), Mat2x2(f32).identity);
    try testing.expectEqual(Mat3x3(f32).fromArrays(.{
        .{1,0,0},
        .{0,1,0},
        .{0,0,1},
    }), Mat3x3(f32).identity);
    try testing.expectEqual(Mat4x4(f32).fromArrays(.{
        .{1,0,0,0},
        .{0,1,0,0},
        .{0,0,1,0},
        .{0,0,0,1},
    }), Mat4x4(f32).identity);
}

test "Matrix identity mul" {
    const mat = Mat3x3(f32).fromArrays(.{
        .{1, 2, 3},
        .{4, 5, 6},
        .{7, 8, 9},
    });

    try testing.expectEqual(mat, mat.mul(Mat3x3(f32).identity));
}

test "Matrix 2x2 determinant" {
    const mat = Mat2x2(f32).fromArrays(.{
        .{1, 2},
        .{3, 4},
    });

    try testing.expectEqual(-2.0, mat.determinant());
}

test "Matrix 2x2 inverse null" {
    const mat = Mat2x2(f32).splat(2.0);
    try testing.expectEqual(null, mat.inverse());
}

test "Matrix 2x2 inverse" {
    const mat = Mat2x2(f32).fromArrays(.{
        .{1, 2},
        .{2, 1},
    });
    const inv = Mat2x2(f32).fromArrays(.{
        .{-1.0/3.0, 2.0/3.0},
        .{2.0/3.0, -1.0/3.0},
    });
    try testing.expect(mat.inverse().?.approxEqlRel(inv));
    try testing.expectEqual(Mat2x2(f32).identity, mat.mul(inv));
}

test "Matrix 3x3 determinant" {
    const mat = Mat3x3(f32).fromArrays(.{
        .{1, 2, 2},
        .{2, 1, 2},
        .{2, 2, 1},
    });

    try testing.expectEqual(5.0, mat.determinant());
}

test "Matrix 3x3 inverse null" {
    const mat = Mat3x3(f32).splat(2.0);
    try testing.expectEqual(null, mat.inverse());
}

test "Matrix 3x3 inverse" {
    const mat = Mat3x3(f32).fromArrays(.{
        .{1, 2, 2},
        .{2, 1, 2},
        .{2, 2, 1},
    });
    const inv = Mat3x3(f32).fromArrays(.{
        .{-3, 2, 2},
        .{2, -3, 2},
        .{2, 2, -3}
    }).divScalar(5.0);
    try testing.expect(mat.inverse().?.approxEqlRel(inv));
    try testing.expect(mat.mul(inv).approxEqlAbs(Mat3x3(f32).identity));
}

test "Matrix 4x4 by Vec4" {
    const mat = Mat4x4(f32).identity.mulScalar(2);
    const vec = Vec(f32, 4).one;

    try testing.expectEqual(mat.mulVec(vec), Vec(f32, 4).splat(2));
}
