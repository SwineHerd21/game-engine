//! Vectors, matricies, etc.
//!
//! Coordinates are right-handed, positive Y axis is up.

// TODO: consider SIMD
// Have vectors as structs because they are usually used one at a time.
// If there is an operation where a large amount of vectors can be operated on at once (raycasts?),
// combine them into `wide` vectors which consist of structs with SIMD @Vector(T) fields
// of the size recommended by std, do the operation and output back to normal vectors.

const std = @import("std");

pub const Vec2 = @import("vec.zig").Vec2;
pub const Vec3 = @import("vec.zig").Vec3;
pub const Vec4 = @import("vec.zig").Vec4;

pub const Vec2i = @import("veci.zig").Vec2i;
pub const Vec3i = @import("veci.zig").Vec3i;
pub const Vec4i = @import("veci.zig").Vec4i;

