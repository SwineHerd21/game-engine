const std = @import("std");
const gl = @import("gl");

const EngineError = @import("../lib.zig").EngineError;
const Allocator = std.mem.Allocator;
const AssetManager = @import("../assets/AssetManager.zig");

const log = std.log.scoped(.engine);

pub const Vertex = struct {
    obj: gl.uint,

    const Self = @This();

    pub fn init(data: []const u8, _: *AssetManager) !Self {
        return .{
            .obj = try compileShader(data, gl.VERTEX_SHADER),
        };
    }

    pub fn deinit(self: *Self, _: Allocator) void {
        gl.DeleteShader(self.obj);
    }
};

pub const Fragment = struct {
    obj: gl.uint,

    const Self = @This();

    pub fn init(data: []const u8, _: *AssetManager) !Self {
        return .{
            .obj = try compileShader(data, gl.FRAGMENT_SHADER),
        };
    }

    pub fn deinit(self: *Self, _: Allocator) void {
        gl.DeleteShader(self.obj);
    }
};

fn compileShader(source: []const u8, shader_type: gl.uint) EngineError!gl.uint {
        const shader_obj = gl.CreateShader(shader_type);
        if (shader_obj == 0) {
            log.err("Failed to create a shader object", .{});
            return EngineError.ShaderCompilationFailure;
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

        return shader_obj;
    }

