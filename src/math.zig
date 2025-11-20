//! Vectors, matricies, etc.
//!
//! Coordinates are right-handed, positive Y axis is up.

// TODO: consider SIMD
// Have vectors as structs because they are usually used one at a time.
// If there is an operation where a large amount of vectors can be operated on at once (raycasts?),
// combine them into `wide` vectors which consist of structs with SIMD @Vector(T) fields
// of the size recommended by std, do the operation and output back to normal vectors.

const std = @import("std");
const zlm_f32 = @import("zlm").as(f32);
const zlm_i32 = @import("zlm").as(i32);

/// Has f32 elements
pub const Vec2 = zlm_f32.Vec2;
/// Has f32 elements
pub const Vec3 = zlm_f32.Vec3;
/// Has f32 elements
pub const Vec4 = zlm_f32.Vec4;

pub const Mat2 = zlm_f32.Mat2;
pub const Mat3 = zlm_f32.Mat3;
pub const Mat4 = zlm_f32.Mat4;

/// Has i32 elements
pub const Vec2i = zlm_i32.Vec2;
/// Has i32 elements
pub const Vec3i = zlm_i32.Vec3;
/// Has i32 elements
pub const Vec4i = zlm_i32.Vec4;

