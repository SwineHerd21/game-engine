//! Holds the OpenGL handler for a compiled shader program.

const std = @import("std");
const gl = @import("gl");

const EngineError = @import("../lib.zig").EngineError;

const log = std.log.scoped(.opengl);

const Shader = @This();

program: gl.uint,

pub fn create(vertex: []const u8, fragment: []const u8) EngineError!Shader {
    const shader_program = gl.CreateProgram();
    if (shader_program == 0) {
        log.err("Failed to create a shader program", .{});
        return EngineError.ShaderCompilationFailure;
    }

    const vertex_shader = try compileShader(shader_program, vertex, gl.VERTEX_SHADER);
    const fragment_shader = try compileShader(shader_program, fragment, gl.FRAGMENT_SHADER);
    // Shader objects are not needed after linking, so delete them
    defer {
        gl.DetachShader(shader_program, vertex_shader);
        gl.DeleteShader(vertex_shader);
        gl.DetachShader(shader_program, fragment_shader);
        gl.DeleteShader(fragment_shader);
    }

    gl.LinkProgram(shader_program);

    // Error checking
    var success: gl.int = undefined;
    var info_log: [1024]u8 = undefined;
    gl.GetProgramiv(shader_program, gl.LINK_STATUS, @ptrCast(&success));
    if (success == 0) {
        gl.GetProgramInfoLog(shader_program, 1024, null, @ptrCast(&info_log));
        log.err("Failed to link shader program: {s}", .{info_log});
        return EngineError.ShaderCompilationFailure;
    }
    gl.ValidateProgram(shader_program);
    gl.GetProgramiv(shader_program, gl.VALIDATE_STATUS, @ptrCast(&success));
    if (success == 0) {
        gl.GetProgramInfoLog(shader_program, 1024, null, @ptrCast(&info_log));
        log.err("Invalid shader program: {s}", .{info_log});
        return EngineError.ShaderCompilationFailure;
    }

    return .{
        .program = shader_program,
    };
}

fn compileShader(program: gl.uint, source: []const u8, shader_type: gl.uint) EngineError!gl.uint {
    const shader_obj = gl.CreateShader(shader_type);
    if (shader_obj == 0) {
        log.err("Failed to create a shader object", .{});
        return EngineError.ShaderCompilationFailure;
    }

    const pointers: [*]const [*]const u8 = &.{ @ptrCast(source) };
    const lengths: [*]const gl.int = &.{ @intCast(source.len) };
    gl.ShaderSource(shader_obj, 1, pointers, lengths);

    gl.CompileShader(shader_obj);

    // Error check
    var success: gl.int = undefined;
    gl.GetShaderiv(shader_obj, gl.COMPILE_STATUS, @ptrCast(&success));
    if (success == 0) {
        var info_log: [1024]u8 = undefined;
        gl.GetShaderInfoLog(shader_obj, 1024, null, @ptrCast(&info_log));
        log.err("Failed to compile {s} shader: {s}", .{
            switch (shader_type) {
                gl.VERTEX_SHADER => "vertex",
                gl.FRAGMENT_SHADER => "fragment",
                gl.GEOMETRY_SHADER => "geometry",
                else => "",
            },
            info_log,
        });
        return EngineError.ShaderCompilationFailure;
    }

    gl.AttachShader(program, shader_obj);
    return shader_obj;
}

pub fn destroy(self: Shader) void {
    gl.DeleteProgram(self.program);
}

// Tells OpenGL to use the shader program.
pub fn use(shader: Shader) void {
    gl.UseProgram(shader.program);
}

/// Represents a GLSL uniform field and its value.
/// Allowed types: bool, i32, u32, f32 and arrays/slices of/to those types.
pub fn Uniform(comptime T: type) type {
    const error_msg = @typeName(T) ++ " is an invalid uniform type: GLSL uniforms can be only of type bool, i32, u32, f32 and arrays/slices of/to those types.";

    const inner = struct {
        pub inline fn validateType(comptime U: type, array: bool) void {
            _=array;
            switch (@typeInfo(U)) {
                .@"bool" => {},
                .int => |i| if (i.bits != 32) {
                    @compileError(error_msg);
                },
                .float => |f| if (f.bits != 32) {
                    @compileError(error_msg);
                },
                // .vector => |v| {
                //     if (v.len < 1 or v.len > 4) {
                //         @compileError(error_msg);
                //     }
                //
                //     switch (@typeInfo(v.child)) {
                //         .@"bool" => if (array) {
                //             @compileError(error_msg);
                //         },
                //         .int => |i| if (i.bits != 32) {
                //             @compileError(error_msg);
                //         },
                //         .float => |f| if (f.bits != 32) {
                //             @compileError(error_msg);
                //         },
                //         else => @compileError(error_msg),
                //     }
                // },
                else => @compileError(error_msg),
            }
        }
    };

    switch (@typeInfo(T)) {
        .array => |a| if (a.len > std.math.maxInt(c_int)) {
            @compileError("Array size is larger than a C int");
        } else {
            inner.validateType(a.child, true);
        },
        .pointer => |p| if (p.size != .slice) {
            @compileError(error_msg);
        } else {
            inner.validateType(p.child, true);
        },
        else => inner.validateType(T, false),
    }

    return struct {
        name: []const u8,
        value: T,

        pub fn new(name: []const u8, value: T) @This() {
            return .{
                .name = name,
                .value = value,
            };
        }
    };
}

/// Set a uniform value in the shader program. Returns false if the uniform could not be found.
/// Must call use() before this function as uniforms are applied to the currently bound shader.
/// Allowed types: bool, i32, u32, f32 and arrays/slices of/to those types.
pub fn setUniform(self: Shader, comptime value_type: type, uniform: Uniform(value_type)) bool {
    const location = gl.GetUniformLocation(self.program, @ptrCast(uniform.name));
    if (location == -1) {
        return false;
    }

    const inner = struct {
        // The array data is passed through an opaque pointer to allow conversion of vectors.
        pub inline fn passArray(comptime child: type, loc: gl.int, len: gl.int, value: *const anyopaque) void {
            switch (@typeInfo(child)) {
                .bool => gl.Uniform1iv(loc, len, @alignCast(@ptrCast(value))),
                .int => |i| if (i.signedness == .signed) {
                    gl.Uniform1iv(loc, len, @alignCast(@ptrCast(value)));
                } else {
                    gl.Uniform1uiv(loc, len, @alignCast(@ptrCast(value)));
                },
                .float => {
                    gl.Uniform1fv(loc, len, @alignCast(@ptrCast(value)));
                },
                // .vector => |v| {
                //     // Converting vectors to array pointers here is ok because vectors of u32,i32,f32
                //     // can be bit cast to arrays of those types. Bool vectors however do not.
                //     switch (@typeInfo(v.child)) {
                //         .int => |i| if (i.signedness == .signed) switch (v.len) {
                //             1 => gl.Uniform1iv(loc, len, @alignCast(@ptrCast(value))),
                //             2 => gl.Uniform2iv(loc, len, @alignCast(@ptrCast(value))),
                //             3 => gl.Uniform3iv(loc, len, @alignCast(@ptrCast(value))),
                //             4 => gl.Uniform4iv(loc, len, @alignCast(@ptrCast(value))),
                //             else => unreachable,
                //         } else switch (v.len) {
                //             1 => gl.Uniform1uiv(loc, len, @alignCast(@ptrCast(value))),
                //             2 => gl.Uniform2uiv(loc, len, @alignCast(@ptrCast(value))),
                //             3 => gl.Uniform3uiv(loc, len, @alignCast(@ptrCast(value))),
                //             4 => gl.Uniform4uiv(loc, len, @alignCast(@ptrCast(value))),
                //             else => unreachable,
                //         },
                //         .float => switch (v.len) {
                //             1 => gl.Uniform1fv(loc, len, @alignCast(@ptrCast(value))),
                //             2 => gl.Uniform2fv(loc, len, @alignCast(@ptrCast(value))),
                //             3 => gl.Uniform3fv(loc, len, @alignCast(@ptrCast(value))),
                //             4 => gl.Uniform4fv(loc, len, @alignCast(@ptrCast(value))),
                //             else => unreachable,
                //         },
                //         else => unreachable,
                //     }
                // },
                else => unreachable,
            }
        }
    };

    switch (@typeInfo(value_type)) {
        .@"bool" => gl.Uniform1i(location, @intFromBool(uniform.value)),
        .int => |i| if (i.signedness == .signed) {
            gl.Uniform1i(location, uniform.value);
        } else {
            gl.Uniform1ui(location, uniform.value);
        },
        .float => gl.Uniform1f(location, uniform.value),
        // .vector => |v| switch (@typeInfo(v.child)) {
        //     .@"bool" => switch (v.len) {
        //         1 => gl.Uniform1i(location, @intFromBool(uniform.value[0])),
        //         2 => gl.Uniform2i(location, @intFromBool(uniform.value[0]), @intFromBool(uniform.value[1])),
        //         3 => gl.Uniform3i(location, @intFromBool(uniform.value[0]), @intFromBool(uniform.value[1]), @intFromBool(uniform.value[2])),
        //         4 => gl.Uniform4i(location, @intFromBool(uniform.value[0]), @intFromBool(uniform.value[1]), @intFromBool(uniform.value[2]), @intFromBool(uniform.value[3])),
        //         else => unreachable,
        //     },
        //     .int => |i| if (i.signedness == .signed) switch (v.len) {
        //         1 => gl.Uniform1i(location, uniform.value[0]),
        //         2 => gl.Uniform2i(location, uniform.value[0], uniform.value[1]),
        //         3 => gl.Uniform3i(location, uniform.value[0], uniform.value[1], uniform.value[2]),
        //         4 => gl.Uniform4i(location, uniform.value[0], uniform.value[1], uniform.value[2], uniform.value[3]),
        //         else => unreachable,
        //     } else switch (v.len) {
        //         1 => gl.Uniform1ui(location, uniform.value[0]),
        //         2 => gl.Uniform2ui(location, uniform.value[0], uniform.value[1]),
        //         3 => gl.Uniform3ui(location, uniform.value[0], uniform.value[1], uniform.value[2]),
        //         4 => gl.Uniform4ui(location, uniform.value[0], uniform.value[1], uniform.value[2], uniform.value[3]),
        //         else => unreachable,
        //     },
        //     .float => switch (v.len) {
        //         1 => gl.Uniform1f(location, uniform.value[0]),
        //         2 => gl.Uniform2f(location, uniform.value[0], uniform.value[1]),
        //         3 => gl.Uniform3f(location, uniform.value[0], uniform.value[1], uniform.value[2]),
        //         4 => gl.Uniform4f(location, uniform.value[0], uniform.value[1], uniform.value[2], uniform.value[3]),
        //         else => unreachable,
        //     },
        //     else => unreachable,
        // },
        .array => |a| inner.passArray(a.child, location, @intCast(a.len), @ptrCast(&uniform.value)),
        .pointer => |p| inner.passArray(p.child, location, @intCast(@as(gl.uint, @truncate(uniform.value.len))), @ptrCast(uniform.value.ptr)),
        else => unreachable,
    }

    return false;
}


// ========== Testing ==========

const expectEqual = std.testing.expectEqual;
const expectEqualDeep = std.testing.expectEqualDeep;
test "Vector to multipointer" {
    const vec: @Vector(5, i32) = @splat(1234);
    const ptr_opaque: *const anyopaque = @ptrCast(&vec);
    const ptr: [*]const i32 = @alignCast(@ptrCast(ptr_opaque));

    try expectEqualDeep(&[5]i32{1234,1234,1234,1234,1234}, ptr[0..5]);
}

test "Uniforms basic types" {
    const b = Uniform(bool){.name = "b", .value = true};
    const int = Uniform(i32){.name = "int", .value = -1234};
    const uint = Uniform(u32){.name = "uint", .value = 1234};
    const float = Uniform(f32){.name = "float", .value = 12.34};

    try expectEqual(true, b.value);
    try expectEqual(-1234, int.value);
    try expectEqual(1234, uint.value);
    try expectEqual(12.34, float.value);
}

// test "Uniform bool vectors" {
//     inline for (1..5) |i| {
//         const vec: @Vector(i, bool) = @splat(true);
//         const uniform = Uniform(@Vector(i, bool)){.name = "b", .value = vec};
//
//         try expectEqual(vec, uniform.value);
//     }
// }
//
// test "Uniform int vectors" {
//     inline for (1..5) |i| {
//         const vec: @Vector(i, i32) = @splat(-1234);
//         const uniform = Uniform(@Vector(i, i32)){.name = "b", .value = vec};
//
//         try expectEqual(vec, uniform.value);
//     }
// }
//
// test "Uniform uint vectors" {
//     inline for (1..5) |i| {
//         const vec: @Vector(i, u32) = @splat(1234);
//         const uniform = Uniform(@Vector(i, u32)){.name = "b", .value = vec};
//
//         try expectEqual(vec, uniform.value);
//     }
// }
//
// test "Uniform float vectors" {
//     inline for (1..5) |i| {
//         const vec: @Vector(i, f32) = @splat(12.34);
//         const uniform = Uniform(@Vector(i, f32)){.name = "b", .value = vec};
//
//         try expectEqual(vec, uniform.value);
//     }
// }

test "Uniform basic arrays" {
    const bs: [5]bool = @splat(true);
    const ints: [5]i32 = @splat(-1234);
    const uints: [5]u32 = @splat(1234);
    const floats: [5]f32 = @splat(12.34);

    const bs_u = Uniform([5]bool){.name = "", .value = bs};
    const ints_u = Uniform([5]i32){.name = "", .value = ints};
    const uints_u = Uniform([5]u32){.name = "", .value = uints};
    const floats_u = Uniform([5]f32){.name = "", .value = floats};

    try expectEqual(bs, bs_u.value);
    try expectEqual(ints, ints_u.value);
    try expectEqual(uints, uints_u.value);
    try expectEqual(floats, floats_u.value);
}

// test "Uniform int vector arrays" {
//     inline for (1..5) |i| {
//         const vec: @Vector(i, i32) = @splat(-1234);
//         const arr: [5]@Vector(i, i32) = @splat(vec);
//
//         const uniform = Uniform([5]@Vector(i, i32)){.name = "b", .value = arr};
//
//         try expectEqual(arr, uniform.value);
//     }
// }
//
// test "Uniform uint vector arrays" {
//     inline for (1..5) |i| {
//         const vec: @Vector(i, u32) = @splat(1234);
//         const arr: [5]@Vector(i, u32) = @splat(vec);
//
//         const uniform = Uniform([5]@Vector(i, u32)){.name = "b", .value = arr};
//
//         try expectEqual(arr, uniform.value);
//     }
// }
//
// test "Uniform float vector arrays" {
//     inline for (1..5) |i| {
//         const vec: @Vector(i, f32) = @splat(-12.34);
//         const arr: [5]@Vector(i, f32) = @splat(vec);
//
//         const uniform = Uniform([5]@Vector(i, f32)){.name = "b", .value = arr};
//
//         try expectEqual(arr, uniform.value);
//     }
// }

test "Uniform basic slices" {
    const bs: [5]bool = @splat(true);
    const ints: [5]i32 = @splat(-1234);
    const uints: [5]u32 = @splat(1234);
    const floats: [5]f32 = @splat(12.34);

    const bs_u = Uniform([]const bool){.name = "", .value = &bs};
    const ints_u = Uniform([]const i32){.name = "", .value = &ints};
    const uints_u = Uniform([]const u32){.name = "", .value = &uints};
    const floats_u = Uniform([]const f32){.name = "", .value = &floats};

    try expectEqual(&bs, bs_u.value);
    try expectEqual(&ints, ints_u.value);
    try expectEqual(&uints, uints_u.value);
    try expectEqual(&floats, floats_u.value);
}

// test "Uniform int vector slices" {
//     inline for (1..5) |i| {
//         const vec: @Vector(i, i32) = @splat(-1234);
//         const arr: [5]@Vector(i, i32) = @splat(vec);
//
//         const uniform = Uniform([]const @Vector(i, i32)){.name = "b", .value = &arr};
//
//         try expectEqual(&arr, uniform.value);
//     }
// }
//
// test "Uniform uint vector slices" {
//     inline for (1..5) |i| {
//         const vec: @Vector(i, u32) = @splat(1234);
//         const arr: [5]@Vector(i, u32) = @splat(vec);
//
//         const uniform = Uniform([]const @Vector(i, u32)){.name = "b", .value = &arr};
//
//         try expectEqual(&arr, uniform.value);
//     }
// }
//
// test "Uniform float vector slices" {
//     inline for (1..5) |i| {
//         const vec: @Vector(i, f32) = @splat(-12.34);
//         const arr: [5]@Vector(i, f32) = @splat(vec);
//
//         const uniform = Uniform([]const @Vector(i, f32)){.name = "b", .value = &arr};
//
//         try expectEqual(&arr, uniform.value);
//     }
// }

// Until Zig supports testing for compile errors(
// test "Uniform invalid types" {
//     comptime {
//         _ = Uniform(u8);
//         _ = Uniform(i4);
//         _ = Uniform([2]@Vector(3, bool));
//         _ = Uniform(type);
//         _ = Uniform(struct {a: u2});
//     }
// }
