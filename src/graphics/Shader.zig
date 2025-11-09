//! Holds the OpenGL handler for a compiled shader program.

const std = @import("std");
const gl = @import("gl");

const EngineError = @import("../lib.zig").EngineError;
const math = @import("../math/math.zig");

const log = std.log.scoped(.opengl);

const Shader = @This();

program: gl.uint,

pub fn init(vertex: []const u8, fragment: []const u8) EngineError!Shader {
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

pub fn deinit(self: *Shader, _: std.mem.Allocator) void {
    gl.DeleteProgram(self.program);
}

// Tells OpenGL to use the shader program.
pub fn use(shader: Shader) void {
    gl.UseProgram(shader.program);
}

/// Set a uniform value in the shader program. Returns false if the uniform could not be found.
/// Must call 'use()' before this function as uniforms are applied to the currently bound shader.
/// Allowed types: bool, i32, u32, f32, math.VecN and arrays/slices of those types.
/// Slices longer than max value of c_int will be truncated.
pub fn setUniform(self: Shader, name: []const u8, value: anytype) bool {
    const T = @TypeOf(value);
    validateUniformType(T);

    // Implementation
    const location = gl.GetUniformLocation(self.program, @ptrCast(name));

    if (location == -1) {
        return false;
    }

    switch (@typeInfo(T)) {
        .@"bool" => gl.Uniform1i(location, @intFromBool(value)),
        .int => |i| if (i.signedness == .signed) {
            gl.Uniform1i(location, value);
        } else {
            gl.Uniform1ui(location, value);
        },
        .float => gl.Uniform1f(location, value),
        .@"struct" => {
            switch (T) {
                math.Vec2 => gl.Uniform2f(location, value.x, value.y),
                math.Vec3 => gl.Uniform3f(location, value.x, value.y, value.z),
                math.Vec4 => gl.Uniform4f(location, value.x, value.y, value.z, value.w),
                else => unreachable,
            }
        },
        .array => |a| passUniformArray(a.child, location, @intCast(a.len), @ptrCast(&value)),
        .pointer => |p| passUniformArray(p.child, location, @intCast(@as(gl.uint, @truncate(value.len))), @ptrCast(value.ptr)),
        else => unreachable,
    }

    return true;
}

// The array data is passed through an opaque pointer to allow conversion of vectors.
inline fn passUniformArray(comptime child: type, loc: gl.int, len: gl.int, val: *const anyopaque) void {
    switch (@typeInfo(child)) {
        .bool => gl.Uniform1iv(loc, len, @alignCast(@ptrCast(val))),
        .int => |i| if (i.signedness == .signed) {
            gl.Uniform1iv(loc, len, @alignCast(@ptrCast(val)));
        } else {
            gl.Uniform1uiv(loc, len, @alignCast(@ptrCast(val)));
        },
        .float => {
            gl.Uniform1fv(loc, len, @alignCast(@ptrCast(val)));
        },
        .@"struct" => {
            switch (child) {
                math.Vec2 => gl.Uniform2fv(loc, len, @alignCast(@ptrCast(val))),
                math.Vec3 => gl.Uniform3fv(loc, len, @alignCast(@ptrCast(val))),
                math.Vec4 => gl.Uniform4fv(loc, len, @alignCast(@ptrCast(val))),
                else => unreachable,
            }
        },
        else => unreachable,
    }
}


pub fn validateUniformType(comptime T: type) void {
    const error_msg = @typeName(T) ++ " is an invalid uniform type: GLSL uniforms can be only of type bool, i32, u32, f32, math.VecN and arrays/slices of those types.";

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
                .@"struct" => {
                    switch (U) {
                        math.Vec2, math.Vec3, math.Vec4 => {},
                        else => @compileError(error_msg),
                    }
                },
                else => @compileError(error_msg),
            }
        }
    };


    switch (@typeInfo(T)) {
        .array => |a| if (a.len > std.math.maxInt(c_int)) {
            @compileError("Array size is larger than a c_int");
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

}
