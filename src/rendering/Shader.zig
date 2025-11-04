//! Holds the OpenGL handler for a compiled shader program.

const std = @import("std");
const gl = @import("gl");

const EngineError = @import("../lib.zig").EngineError;

const log = std.log.scoped(.engine);

const Shader = @This();

program: gl.uint,

// Pass in shader source code. Call destroy() when shader is no longer needed.
pub fn create(vertex: []const u8, fragment: []const u8) EngineError!Shader {
    const shader_program = gl.CreateProgram();
    if (shader_program == 0) {
        log.err("Failed to create a shader program", .{});
        return EngineError.ShaderCompilationFailure;
    }

    const vertex_shader = try compileShader(shader_program, vertex, gl.VERTEX_SHADER);
    const fragment_shader = try compileShader(shader_program, fragment, gl.FRAGMENT_SHADER);

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

    // Shader objects are not needed after linking, so delete them
    gl.DetachShader(shader_program, vertex_shader);
    gl.DeleteShader(vertex_shader);
    gl.DetachShader(shader_program, fragment_shader);
    gl.DeleteShader(fragment_shader);

    return .{
        .program = shader_program,
    };
}

fn compileShader(program: gl.uint, source: []const u8, shader_type: gl.uint) EngineError!gl.uint {
    const shader_obj = gl.CreateShader(shader_type);
    if (shader_obj == 0) {
        log.err("Failed to create a shader", .{});
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
/// Allowed types: bool, i32, u32, f32, 1-4 element vectors of previous types, matricies and arrays/slices of/to those types (except for vectors of bool, as those use 1 bit per value instead of 1 byte).
pub fn Uniform(comptime T: type) type {
    const error_msg = "Invalid uniform type: GLSL uniforms can be only of type bool, i32, u32, f32, 1-4 element vectors of previous types, matricies and arrays/slices of/to those types (except for vectors of bool, as those use 1 bit per value instead of 1 byte).";

    const inner = struct {
        pub fn validateType(comptime U: type, array: bool) void {
            switch (@typeInfo(U)) {
                .@"bool" => {},
                .int => |i| {
                    if (i.bits != 32) {
                        @compileError(error_msg);
                    }
                },
                .float => |f| {
                    if (f.bits != 32) {
                        @compileError(error_msg);
                    }
                },
                .vector => |v| {
                    if (v.len < 1 or v.len > 4) {
                        @compileError(error_msg);
                    }

                    switch (@typeInfo(v.child)) {
                        .@"bool" => if (array) {
                            @compileError(error_msg);
                        },
                        .int => |i| {
                            if (i.bits != 32) {
                                @compileError(error_msg);
                            }
                        },
                        .float => |f| {
                            if (f.bits != 32) {
                                @compileError(error_msg);
                            }
                        },
                        else => @compileError(error_msg),
                    }
                },
                .@"struct" => {
                    @compileLog("TODO: add matrix support for uniforms");
                    @compileError(error_msg);
                },
                else => @compileError(error_msg),
            }
        }
    };

    switch (@typeInfo(T)) {
        .array => |a| inner.validateType(a.child, true),
        .pointer => |p| {
            if (p.size != .slice) {
                @compileError(error_msg);
            } else {
                inner.validateType(p.child, true);
            }
        },
        else => inner.validateType(T, false),
    }

    return struct {
        name: []const u8,
        value: T,
    };
}

/// Set a uniform value in the shader program. Returns false if the uniform could not be found.
/// Must call use() before this function as uniforms are applied to the currently bound shader.
/// Allowed types: bool, i32, u32, f32, 1-4 element vectors of previous types, matricies and arrays/slices of/to those types (except for vectors of bool, as those use 1 bit per value instead of 1 byte).
pub fn setUniform(self: Shader, comptime value_type: type, uniform: Uniform(value_type)) bool {
    const location = gl.GetUniformLocation(self.program, @ptrCast(uniform.name));
    if (location == -1) {
        return false;
    }

    const inner = struct {
        pub fn passArray(comptime child: type, len: usize, value: [*]anyopaque) void {
            switch (@typeInfo(child)) {
                .bool => gl.Uniform1iv(location, len, @ptrCast(value)),
                .int => |i| if (i.signedness == .signed) {
                    gl.Uniform1iv(location, len, @ptrCast(value));
                } else {
                    gl.Uniform1uiv(location, len, @ptrCast(value));
                },
                .float => gl.Uniform1fv(location, len, @ptrCast(value)),
                .vector => |v| {
                    // Converting vectors to pointers here is ok because vectors of u32,i32,f32
                    // have the same layout as arrays of those types. Bool vectors whoever do not.
                    switch (@typeInfo(v.child)) {
                        .int => |i| if (i.signedness == .signed) switch (v.len) {
                            1 => gl.Uniform1iv(location, len, @ptrCast(value)),
                            2 => gl.Uniform2iv(location, len, @ptrCast(value)),
                            3 => gl.Uniform3iv(location, len, @ptrCast(value)),
                            4 => gl.Uniform4iv(location, len, @ptrCast(value)),
                        } else switch (v.len) {
                            1 => gl.Uniform1uiv(location, len, @ptrCast(value)),
                            2 => gl.Uniform2uiv(location, len, @ptrCast(value)),
                            3 => gl.Uniform3uiv(location, len, @ptrCast(value)),
                            4 => gl.Uniform4uiv(location, len, @ptrCast(value)),
                        },
                        .float => switch (v.len) {
                            1 => gl.Uniform1fv(location, len, @ptrCast(value)),
                            2 => gl.Uniform2fv(location, len, @ptrCast(value)),
                            3 => gl.Uniform3fv(location, len, @ptrCast(value)),
                            4 => gl.Uniform4fv(location, len, @ptrCast(value)),
                        },
                        else => unreachable,
                    }
                }
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
        .vector => |v| switch (@typeInfo(v.child)) {
            .@"bool" => switch (v.len) {
                1 => gl.Uniform1i(location, @intFromBool(uniform.value[0])),
                2 => gl.Uniform2i(location, @intFromBool(uniform.value[0]), @intFromBool(uniform.value[1])),
                3 => gl.Uniform3i(location, @intFromBool(uniform.value[0]), @intFromBool(uniform.value[1]), @intFromBool(uniform.value[2])),
                4 => gl.Uniform4i(location, @intFromBool(uniform.value[0]), @intFromBool(uniform.value[1]), @intFromBool(uniform.value[2]), @intFromBool(uniform.value[3])),
            },
            .int => |i| if (i.signedness == .signed) switch (v.len) {
                1 => gl.Uniform1i(location, uniform.value[0]),
                2 => gl.Uniform2i(location, uniform.value[0], uniform.value[1]),
                3 => gl.Uniform3i(location, uniform.value[0], uniform.value[1], uniform.value[2]),
                4 => gl.Uniform4i(location, uniform.value[0], uniform.value[1], uniform.value[2], uniform.value[3]),
            } else switch (v.len) {
                1 => gl.Uniform1ui(location, uniform.value[0]),
                2 => gl.Uniform2ui(location, uniform.value[0], uniform.value[1]),
                3 => gl.Uniform3ui(location, uniform.value[0], uniform.value[1], uniform.value[2]),
                4 => gl.Uniform4ui(location, uniform.value[0], uniform.value[1], uniform.value[2], uniform.value[3]),
            },
            .float => switch (v.len) {
                1 => gl.Uniform1f(location, uniform.value[0]),
                2 => gl.Uniform2f(location, uniform.value[0], uniform.value[1]),
                3 => gl.Uniform3f(location, uniform.value[0], uniform.value[1], uniform.value[2]),
                4 => gl.Uniform4f(location, uniform.value[0], uniform.value[1], uniform.value[2], uniform.value[3]),
            },
            else => unreachable,
        },
        .@"struct" => {
            unreachable;
            // TODO: add matrix support
        },
        .array => |a| inner.passArray(a.child, uniform.value.len, @ptrCast(&uniform.value)),
        .pointer => |p| inner.passArray(p.child, uniform.value.len, @ptrCast(&uniform.value)),
        else => unreachable,
    }

    return false;
}


// ========== Testing ==========

const expectEqual = std.testing.expectEqual;
test "Uniforms basic types" {
    const b = Uniform(bool){.name = "b", .value = true};
    const int = Uniform(i32){.name = "int", .value = -1234};
    const uint = Uniform(u32){.name = "uint", .value = 1234};
    const float = Uniform(f32){.name = "float", .value = 12.34};

    try expectEqual(b.value, true);
    try expectEqual(int.value, -1234);
    try expectEqual(uint.value, 1234);
    try expectEqual(float.value, 12.34);
}

test "Uniform bool vectors" {
    inline for (1..5) |i| {
        const vec: @Vector(i, bool) = @splat(true);
        const uniform = Uniform(@Vector(i, bool)){.name = "b", .value = vec};

        try expectEqual(uniform.value, vec);
    }
}

test "Uniform int vectors" {
    inline for (1..5) |i| {
        const vec: @Vector(i, i32) = @splat(-1234);
        const uniform = Uniform(@Vector(i, i32)){.name = "b", .value = vec};

        try expectEqual(uniform.value, vec);
    }
}

test "Uniform uint vectors" {
    inline for (1..5) |i| {
        const vec: @Vector(i, u32) = @splat(1234);
        const uniform = Uniform(@Vector(i, u32)){.name = "b", .value = vec};

        try expectEqual(uniform.value, vec);
    }
}

test "Uniform float vectors" {
    inline for (1..5) |i| {
        const vec: @Vector(i, f32) = @splat(12.34);
        const uniform = Uniform(@Vector(i, f32)){.name = "b", .value = vec};

        try expectEqual(uniform.value, vec);
    }
}

test "Uniform basic arrays" {
    const bs: [5]bool = @splat(true);
    const ints: [5]i32 = @splat(-1234);
    const uints: [5]u32 = @splat(1234);
    const floats: [5]f32 = @splat(12.34);

    const bs_u = Uniform([5]bool){.name = "", .value = bs};
    const ints_u = Uniform([5]i32){.name = "", .value = ints};
    const uints_u = Uniform([5]u32){.name = "", .value = uints};
    const floats_u = Uniform([5]f32){.name = "", .value = floats};

    try expectEqual(bs_u.value, bs);
    try expectEqual(ints_u.value, ints);
    try expectEqual(uints_u.value, uints);
    try expectEqual(floats_u.value, floats);
}

test "Uniform int vector arrays" {
    inline for (1..5) |i| {
        const vec: @Vector(i, i32) = @splat(-1234);
        const arr: [5]@Vector(i, i32) = @splat(vec);

        const uniform = Uniform([5]@Vector(i, i32)){.name = "b", .value = arr};

        try expectEqual(uniform.value, arr);
    }
}

test "Uniform uint vector arrays" {
    inline for (1..5) |i| {
        const vec: @Vector(i, u32) = @splat(1234);
        const arr: [5]@Vector(i, u32) = @splat(vec);

        const uniform = Uniform([5]@Vector(i, u32)){.name = "b", .value = arr};

        try expectEqual(uniform.value, arr);
    }
}

test "Uniform float vector arrays" {
    inline for (1..5) |i| {
        const vec: @Vector(i, f32) = @splat(-12.34);
        const arr: [5]@Vector(i, f32) = @splat(vec);

        const uniform = Uniform([5]@Vector(i, f32)){.name = "b", .value = arr};

        try expectEqual(uniform.value, arr);
    }
}

test "Uniform basic slices" {
    const bs: [5]bool = @splat(true);
    const ints: [5]i32 = @splat(-1234);
    const uints: [5]u32 = @splat(1234);
    const floats: [5]f32 = @splat(12.34);

    const bs_u = Uniform([]const bool){.name = "", .value = &bs};
    const ints_u = Uniform([]const i32){.name = "", .value = &ints};
    const uints_u = Uniform([]const u32){.name = "", .value = &uints};
    const floats_u = Uniform([]const f32){.name = "", .value = &floats};

    try expectEqual(bs_u.value, &bs);
    try expectEqual(ints_u.value, &ints);
    try expectEqual(uints_u.value, &uints);
    try expectEqual(floats_u.value, &floats);
}

test "Uniform int vector slices" {
    inline for (1..5) |i| {
        const vec: @Vector(i, i32) = @splat(-1234);
        const arr: [5]@Vector(i, i32) = @splat(vec);

        const uniform = Uniform([]const @Vector(i, i32)){.name = "b", .value = &arr};

        try expectEqual(uniform.value, &arr);
    }
}

test "Uniform uint vector slices" {
    inline for (1..5) |i| {
        const vec: @Vector(i, u32) = @splat(1234);
        const arr: [5]@Vector(i, u32) = @splat(vec);

        const uniform = Uniform([]const @Vector(i, u32)){.name = "b", .value = &arr};

        try expectEqual(uniform.value, &arr);
    }
}

test "Uniform float vector slices" {
    inline for (1..5) |i| {
        const vec: @Vector(i, f32) = @splat(-12.34);
        const arr: [5]@Vector(i, f32) = @splat(vec);

        const uniform = Uniform([]const @Vector(i, f32)){.name = "b", .value = &arr};

        try expectEqual(uniform.value, &arr);
    }
}
