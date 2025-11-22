//! Vectors, matricies, etc.
//!
//! Coordinates are right-handed, positive Y axis is up. Matricies are stored in column-major order.
//!
//! Vectors and matricies can be bit cast to and from arrays of suitable length and types.

// TODO: consider SIMD
// Have vectors as structs because they are usually used one at a time.
// If there is an operation where a large amount of vectors can be operated on at once (raycasts?),
// combine them into `wide` vectors which consist of structs with SIMD @Vector(T) fields
// of the size recommended by std, do the operation and output back to normal vectors.

const std = @import("std");

// ========== Vectors ==========

const vecf = @import("vectors/vecf.zig");
const veci = @import("vectors/veci.zig");

const Vec2float = vecf.Vec2float;
const Vec3float = vecf.Vec3float;
const Vec4float = vecf.Vec4float;
const Vec2int = veci.Vec2int;
const Vec3int = veci.Vec3int;
const Vec4int = veci.Vec4int;

/// Select a required vector type
/// `T` must be a float or signed integer
/// `dimension` must be 2, 3 or 4
pub fn Vec(T: type, dimension: comptime_int) type {
    const errMsg = std.fmt.comptimePrint("Vectors of type {s} and dimension {} are not supported", .{@typeName(T), dimension});
    return switch (dimension) {
        2 => switch (@typeInfo(T)) {
            .int => |i| if (i.signedness == .signed) Vec2int(T) else @compileError(errMsg),
            .float => Vec2float(T),
            else => @compileError(errMsg),
        },
        3 => switch (@typeInfo(T)) {
            .int => |i| if (i.signedness == .signed) Vec3int(T) else @compileError(errMsg),
            .float => Vec3float(T),
            else => @compileError(errMsg),
        },
        4 => switch (@typeInfo(T)) {
            .int => |i| if (i.signedness == .signed) Vec4int(T) else @compileError(errMsg),
            .float => Vec4float(T),
            else => @compileError(errMsg),
        },
        else => @compileError(errMsg),
    };
}

/// Has f32 elements
pub const Vec2f = Vec(f32, 2);
/// Has f32 elements
pub const Vec3f = Vec(f32, 3);
/// Has f32 elements
pub const Vec4f = Vec(f32, 4);

/// Has f64 elements
pub const Vec2d = Vec(f64, 2);
/// Has f64 elements
pub const Vec3d = Vec(f64, 3);
/// Has f64 elements
pub const Vec4d = Vec(f64, 4);

/// Has i32 elements
pub const Vec2i = Vec(i32, 2);
/// Has i32 elements
pub const Vec3i = Vec(i32, 3);
/// Has i32 elements
pub const Vec4i = Vec(i32, 4);

// ========== Matricies ==========

test {
    std.testing.refAllDeclsRecursive(@This());
}

const MatRectangle = @import("matricies/mat_rectangle.zig").MatRectangle;
const mat_square = @import("matricies/mat_square.zig");

/// Select a required matrix type
/// `T` must be a float
/// `rows` and `columns` must be 2, 3 or 4
pub fn MatNxM(T: type, rows: comptime_int, columns: comptime_int) type {
    if (@typeInfo(T) != .float) @compileError("Matricies can only contain floats");
    const errMsg = std.fmt.comptimePrint("Matricies of size {}x{} are not supported", .{rows, columns});
    if (rows < 2 or columns < 2 or rows > 4 or columns > 4) @compileError(errMsg);

    if (rows == columns) return switch (rows) {
        2 => mat_square.Mat2x2(T),
        else => @compileError(errMsg),
    };
    return MatRectangle(T, rows, columns);
}

pub const Mat2 = MatNxM(f32, 2, 2);

pub const Mat2x3 = MatNxM(f32, 2, 3);
pub const Mat2x4 = MatNxM(f32, 2, 4);
pub const Mat3x2 = MatNxM(f32, 3, 2);
pub const Mat3x4 = MatNxM(f32, 3, 4);
pub const Mat4x2 = MatNxM(f32, 4, 2);
pub const Mat4x3 = MatNxM(f32, 4, 3);
