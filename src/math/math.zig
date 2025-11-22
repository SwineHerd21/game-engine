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

pub const Vec2float = @import("vectors/vecf.zig").Vec2float;
pub const Vec3float = @import("vectors/vecf.zig").Vec3float;
pub const Vec4float = @import("vectors/vecf.zig").Vec4float;
pub const Vec2int = @import("vectors/veci.zig").Vec2int;
pub const Vec3int = @import("vectors/veci.zig").Vec3int;
pub const Vec4int = @import("vectors/veci.zig").Vec4int;

/// Has f32 elements
pub const Vec2f = Vec2float(f32);
/// Has f32 elements
pub const Vec3f = Vec3float(f32);
/// Has f32 elements
pub const Vec4f = Vec4float(f32);

/// Has f64 elements
pub const Vec2d = Vec2float(f64);
/// Has f64 elements
pub const Vec3d = Vec3float(f64);
/// Has f64 elements
pub const Vec4d = Vec4float(f64);

/// Has i32 elements
pub const Vec2i = Vec2int(i32);
/// Has i32 elements
pub const Vec3i = Vec3int(i32);
/// Has i32 elements
pub const Vec4i = Vec4int(i32);

