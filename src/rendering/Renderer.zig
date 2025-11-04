//! OpenGL renderer

const std = @import("std");
const gl = @import("gl");

const native = @import("../platform.zig").native;

const Window = @import("../Window.zig");
const EngineError = @import("../lib.zig").EngineError;

const Renderer = @This();

const log = std.log.scoped(.engine);

pub const RenderMode = enum {
    Solid,
    Wireframe,
};

// OpenGL runtime loaded functions
var procs: gl.ProcTable = undefined;

vao: gl.uint,
vbo: gl.uint,
shader_program: gl.uint,
vertex_shader: gl.uint,
fragment_shader: gl.uint,

/// Call deinit at the end
pub fn init(allocator: std.mem.Allocator) EngineError!Renderer {
    // Load OpenGL functions
    if (!procs.init(native.getProcAddress)) return EngineError.InitFailure;
    gl.makeProcTableCurrent(&procs);

    const gl_version: [*:0]const u8 = gl.GetString(gl.VERSION).?;
    log.info("Rendering with OpenGL {s}", .{ gl_version });

    // Default winding order is CCW
    gl.Enable(gl.CULL_FACE);

    var renderer: Renderer = .{
        .vao = undefined,
        .vbo = undefined,
        .shader_program = undefined,
        .vertex_shader = undefined,
        .fragment_shader = undefined,
    };

    renderer.createVertexArray();
    try renderer.compileShaders(allocator);

    return renderer;
}

pub fn deinit(self: Renderer) void {
    // must always happen last
    defer gl.makeProcTableCurrent(null);

    // Clean shaders
    {
        defer gl.DeleteProgram(self.shader_program);

        gl.DetachShader(self.shader_program, self.vertex_shader);
        gl.DeleteShader(self.vertex_shader);
        gl.DetachShader(self.shader_program, self.fragment_shader);
        gl.DeleteShader(self.fragment_shader);
    }

    // Clean buffers
    gl.DeleteBuffers(1, @ptrCast(&self.vbo));
    gl.DeleteVertexArrays(1, @ptrCast(&self.vao));
}

pub fn adjustViewport(width: i32, height: i32) void {
    gl.Viewport(0, 0, width, height);
}

pub fn setRenderMode(mode: RenderMode) void {
    gl.PolygonMode(gl.FRONT_AND_BACK, switch (mode) {
        .Solid => gl.LINE,
        .Wireframe => gl.FILL,
    });
}

pub fn createVertexArray(self: *Renderer) void {
    const verts = [_]f32{
        -1.0, -1.0, 0.0,    // bottom left
        1.0, -1.0, 0.0,     // bottom right
        0.0, 1.0, 0.0,      // top
    };

    gl.GenVertexArrays(1, @ptrCast(&self.vao));
    gl.GenBuffers(1, @ptrCast(&self.vbo));

    gl.BindVertexArray(self.vao);
    gl.BindBuffer(gl.ARRAY_BUFFER, self.vbo);
    gl.BufferData(gl.ARRAY_BUFFER, @sizeOf(@TypeOf(verts)), &verts, gl.STATIC_DRAW);

    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * @sizeOf(f32), 0);
    gl.EnableVertexAttribArray(0);
}

const vs_path: []const u8 = "shader.vert";
const fs_path: []const u8 = "shader.frag";

pub fn compileShaders(self: *Renderer, allocator: std.mem.Allocator) EngineError!void {
    self.shader_program = gl.CreateProgram();
    if (self.shader_program == 0) {
        log.err("Failed to create a shader program", .{});
        return EngineError.ShaderCompilationFailure;
    }

    // TODO: Make the path to shaders reasonable
    self.vertex_shader = try createShader("shaders/" ++ vs_path, self.shader_program, gl.VERTEX_SHADER, allocator);
    self.fragment_shader = try createShader("shaders/" ++ fs_path, self.shader_program, gl.FRAGMENT_SHADER, allocator);

    var success: gl.int = undefined;
    var info_log: [1024]u8 = undefined;

    gl.LinkProgram(self.shader_program);

    gl.GetProgramiv(self.shader_program, gl.LINK_STATUS, @ptrCast(&success));
    if (success == 0) {
        gl.GetProgramInfoLog(self.shader_program, 1024, null, @ptrCast(&info_log));
        std.log.err("Failed to link shader program: {s}", .{info_log});
        return EngineError.ShaderCompilationFailure;
    }

    gl.ValidateProgram(self.shader_program);
    gl.GetProgramiv(self.shader_program, gl.VALIDATE_STATUS, @ptrCast(&success));
    if (success == 0) {
        gl.GetProgramInfoLog(self.shader_program, 1024, null, @ptrCast(&info_log));
        std.log.err("Invalid shader program: {s}", .{info_log});
        return EngineError.ShaderCompilationFailure;
    }
}

// Load a shader file, returns the created shader handle
fn createShader(
    path: []const u8,
    program: gl.uint,
    shader_type: gl.@"enum",
    allocator: std.mem.Allocator
) EngineError!gl.uint {
    const shader_file = std.fs.cwd().openFile(path, .{}) catch {
        std.log.err("Shader file '{s}' does not exist or is inaccessible", .{ path });
        return EngineError.IOError;
    };
    defer shader_file.close();
    const file_stat = shader_file.stat() catch {
        std.log.err("Shader file '{s}' is corrupted", .{ path });
        return EngineError.IOError;
    };
    const shader_text = allocator.alloc(u8, file_stat.size) catch {
        std.log.err("Could not allocate memory", .{});
        return EngineError.OutOfMemory;
    };
    defer allocator.free(shader_text);

    _ = shader_file.read(shader_text) catch {
        std.log.err("Could not read shader file '{s}'", .{ path });
        return EngineError.OutOfMemory;
    };

    const shader_obj = gl.CreateShader(shader_type);
    if (shader_obj == 0) {
        log.err("Failed to create a shader of type {X}", .{shader_type});
        return EngineError.ShaderCompilationFailure;
    }

    const pointers: [*]const [*]const u8 = &.{ @ptrCast(shader_text) };
    const lengths: [*]const gl.int = &.{ @intCast(shader_text.len) };
    gl.ShaderSource(shader_obj, 1, pointers, lengths);

    gl.CompileShader(shader_obj);

    var success: gl.int = undefined;
    gl.GetShaderiv(shader_obj, gl.COMPILE_STATUS, @ptrCast(&success));

    if (success == 0) {
        var info_log: [1024]u8 = undefined;
        gl.GetShaderInfoLog(shader_obj, 1024, null, @ptrCast(&info_log));
        std.log.err("Failed to compile shader of type {X}: {s}", .{shader_type, info_log});
        return EngineError.ShaderCompilationFailure;
    }

    gl.AttachShader(program, shader_obj);
    return shader_obj;
}

pub fn render(self: Renderer, window: Window) void {
    gl.Clear(gl.COLOR_BUFFER_BIT);

    gl.UseProgram(self.shader_program);
    gl.BindVertexArray(self.vao);
    gl.DrawArrays(gl.TRIANGLES, 0, 3);

    window.swapBuffers();
}
