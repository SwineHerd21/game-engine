//! Holds the OpenGL handler for a compiled shader program.

const std = @import("std");
const gl = @import("gl");

const math = @import("../math/math.zig");
const EngineError = @import("../lib.zig").EngineError;
const AssetManager = @import("../assets/AssetManager.zig");

const shaders = @import("shaders.zig");
const Texture = @import("Texture.zig");

const log_gl = std.log.scoped(.opengl);

const Material = @This();

program: gl.uint,
vertex_shader: shaders.Vertex,
fragment_shader: shaders.Fragment,
texture: ?Texture,

pub fn init(data: []const u8, assets: *AssetManager) EngineError!Material {
    // TODO: figure out how to embed unifroms into material files
    const Zon = struct {
        vertex: []const u8,
        fragment: []const u8,
        texture: ?[]const u8,
    };
    const zon = try assets.parseZon(Zon, data);

    const shader_program = gl.CreateProgram();
    if (shader_program == 0) {
        log_gl.err("Failed to create a shader program", .{});
        return EngineError.ShaderCompilationFailure;
    }
    errdefer gl.DeleteProgram(shader_program);

    const vertex_shader = try assets.getOrLoad(shaders.Vertex, zon.vertex);
    const fragment_shader = try assets.getOrLoad(shaders.Fragment, zon.fragment);

    gl.AttachShader(shader_program, vertex_shader.obj);
    gl.AttachShader(shader_program, fragment_shader.obj);
    errdefer gl.DetachShader(shader_program, vertex_shader.obj);
    errdefer gl.DetachShader(shader_program, fragment_shader.obj);

    gl.LinkProgram(shader_program);

    // Error checking
    var success: gl.int = undefined;
    var info_log: [1024]u8 = undefined;
    gl.GetProgramiv(shader_program, gl.LINK_STATUS, @ptrCast(&success));
    if (success == 0) {
        gl.GetProgramInfoLog(shader_program, 1024, null, @ptrCast(&info_log));
        log_gl.err("Failed to link shader program: {s}", .{info_log});
        return EngineError.ShaderCompilationFailure;
    }
    gl.ValidateProgram(shader_program);
    gl.GetProgramiv(shader_program, gl.VALIDATE_STATUS, @ptrCast(&success));
    if (success == 0) {
        gl.GetProgramInfoLog(shader_program, 1024, null, @ptrCast(&info_log));
        log_gl.err("Invalid shader program: {s}", .{info_log});
        return EngineError.ShaderCompilationFailure;
    }

    var material = Material{
        .program = shader_program,
        .vertex_shader = vertex_shader,
        .fragment_shader = fragment_shader,
        .texture = null,
    };

    if (zon.texture) |texture_path| {
        const texture = try assets.getOrLoad(Texture, texture_path);
        material.setUniform("Texture", @as(i32, 0));
        material.texture = texture;
    }

    return material;
}


pub fn deinit(self: *Material, _: std.mem.Allocator) void {
    gl.DetachShader(self.program, self.vertex_shader.obj);
    gl.DetachShader(self.program, self.fragment_shader.obj);
    gl.DeleteProgram(self.program);
}

// Tells OpenGL to use the shader program.
pub fn use(self: Material) void {
    gl.UseProgram(self.program);
    if (self.texture) |texture| {
        gl.ActiveTexture(gl.TEXTURE0);
        gl.BindTexture(gl.TEXTURE_2D, texture.handle);
    }
}

/// Set a uniform value in the shader program if it exists.
/// Allowed types: `bool`, `i32`, `u32`, `f32`, `math.VecNf`, `math.VecNi` and arrays/slices of those types.
/// Slices longer than max value of `c_int` will be truncated.
pub fn setUniform(self: Material, name: []const u8, value: anytype) void {
    const T = @TypeOf(value);
    validateUniformType(T);

    // Implementation
    const location = gl.GetUniformLocation(self.program, @ptrCast(name));

    if (location == -1) {
        return;
    }

    // OpenGL uniform functions apply to the currently bound shader
    self.use();
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
                math.Vec2f => gl.Uniform2f(location, value.x(), value.y()),
                math.Vec3f => gl.Uniform3f(location, value.x(), value.y(), value.z()),
                math.Vec4f => gl.Uniform4f(location, value.x(), value.y(), value.z(), value.w()),
                math.Vec2i => gl.Uniform2i(location, value.x(), value.y()),
                math.Vec3i => gl.Uniform3i(location, value.x(), value.y(), value.z()),
                math.Vec4i => gl.Uniform4i(location, value.x(), value.y(), value.z(), value.w()),
                math.Mat2, math.Mat3, math.Mat4,
                math.Mat2x3, math.Mat2x4,
                math.Mat3x2, math.Mat3x4,
                math.Mat4x2, math.Mat4x3 => |m| {
                    const arr: [m.rows*m.columns]f32 = @bitCast(value);
                    passUniformArray(T, location, 1, @ptrCast(&arr));
                },
                else => unreachable,
            }
        },
        .array => |a| passUniformArray(a.child, location, @intCast(a.len), @ptrCast(&value)),
        .pointer => |p| passUniformArray(p.child, location, @intCast(@as(gl.uint, @truncate(value.len))), @ptrCast(value.ptr)),
        else => unreachable,
    }
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
                math.Vec2f => gl.Uniform2fv(loc, len, @alignCast(@ptrCast(val))),
                math.Vec3f => gl.Uniform3fv(loc, len, @alignCast(@ptrCast(val))),
                math.Vec4f => gl.Uniform4fv(loc, len, @alignCast(@ptrCast(val))),
                math.Vec2i => gl.Uniform2iv(loc, len, @alignCast(@ptrCast(val))),
                math.Vec3i => gl.Uniform3iv(loc, len, @alignCast(@ptrCast(val))),
                math.Vec4i => gl.Uniform4iv(loc, len, @alignCast(@ptrCast(val))),
                math.Mat2 => gl.UniformMatrix2fv(loc, len, 0, @alignCast(@ptrCast(val))),
                math.Mat3 => gl.UniformMatrix3fv(loc, len, 0, @alignCast(@ptrCast(val))),
                math.Mat4 => gl.UniformMatrix4fv(loc, len, 0, @alignCast(@ptrCast(val))),
                math.Mat2x3 => gl.UniformMatrix2x3fv(loc, len, 0, @alignCast(@ptrCast(val))),
                math.Mat2x4 => gl.UniformMatrix2x4fv(loc, len, 0, @alignCast(@ptrCast(val))),
                math.Mat3x2 => gl.UniformMatrix3x2fv(loc, len, 0, @alignCast(@ptrCast(val))),
                math.Mat3x4 => gl.UniformMatrix3x4fv(loc, len, 0, @alignCast(@ptrCast(val))),
                math.Mat4x2 => gl.UniformMatrix4x2fv(loc, len, 0, @alignCast(@ptrCast(val))),
                math.Mat4x3 => gl.UniformMatrix4x3fv(loc, len, 0, @alignCast(@ptrCast(val))),
                else => unreachable,
            }
        },
        else => unreachable,
    }
}


pub fn validateUniformType(comptime T: type) void {
    const error_msg = @typeName(T) ++ " is an invalid uniform type: GLSL uniforms can be only of type bool, i32, u32, f32, math.VecNf, math.VecNi and arrays/slices of those types.";

    const inner = struct {
        pub inline fn validateType(comptime U: type, array: bool) void {
            _=array;
            switch (@typeInfo(U)) {
                .@"bool" => {},
                .comptime_int, .comptime_float => @compileError("comptime_int/comptime_float values are not allowed in uniforms, please cast them"),
                .int => |i| if (i.bits != 32) {
                    @compileError(error_msg);
                },
                .float => |f| if (f.bits != 32) {
                    @compileError(error_msg);
                },
                .@"struct" => {
                    switch (U) {
                        math.Vec2f, math.Vec3f, math.Vec4f,
                        math.Vec2i, math.Vec3i, math.Vec4i,
                        math.Mat2, math.Mat3, math.Mat4,
                        math.Mat2x3, math.Mat2x4,
                        math.Mat3x2, math.Mat3x4,
                        math.Mat4x2, math.Mat4x3 => {},
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
