const std = @import("std");
const gl = @import("gl");

const EngineError = @import("../lib.zig").EngineError;
const Allocator = std.mem.Allocator;

const log = std.log.scoped(.engine);

const Self = @This();

obj: gl.uint,
type: Type,

pub const Type = enum {
    vertex,
    fragment,
    geometry,
    tesselation_control,
    tesselation_evaluation,
    compute,
};

pub fn init(source: []const u8, shader_type: Type) !Self {
    return .{
        .obj = try compileShader(source, shader_type),
        .type = shader_type,
    };
}

pub fn deinit(self: Self) void {
    gl.DeleteShader(self.obj);
}

fn compileShader(source: []const u8, shader_type: Type) EngineError!gl.uint {
    const s_type: gl.uint = switch (shader_type) {
        .vertex => gl.VERTEX_SHADER,
        .fragment => gl.FRAGMENT_SHADER,
        .geometry => gl.GEOMETRY_SHADER,
        .tesselation_control => gl.TESS_CONTROL_SHADER,
        .tesselation_evaluation => gl.TESS_EVALUATION_SHADER,
        .compute => gl.COMPUTE_SHADER,
    };

    const shader_obj = gl.CreateShader(s_type);
    if (shader_obj == 0) {
        log.err("Failed to create a shader object", .{});
        return error.ShaderCompilationFailure;
    }
    errdefer gl.DeleteShader(shader_obj);

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
        log.err("Failed to compile {t} shader: {s}", .{ shader_type, info_log });
        return error.ShaderCompilationFailure;
    }

    return shader_obj;
}

