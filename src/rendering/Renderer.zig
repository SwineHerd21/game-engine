//! OpenGL renderer

const std = @import("std");
const gl = @import("gl");

const native = @import("../platform.zig").native;

const Window = @import("../Window.zig");
const EngineError = @import("../lib.zig").EngineError;

const Renderer = @This();
const Shader = @import("Shader.zig");

const log = std.log.scoped(.engine);

pub const RenderMode = enum {
    Solid,
    Wireframe,
};

// OpenGL runtime loaded functions
var procs: gl.ProcTable = undefined;

vao: gl.uint = undefined,
vbo: gl.uint = undefined,
ebo: gl.uint = undefined,
shader: Shader = undefined,

/// Call deinit at the end
pub fn init() EngineError!Renderer {
    // Load OpenGL functions
    if (!procs.init(native.getProcAddress)) return EngineError.InitFailure;
    gl.makeProcTableCurrent(&procs);

    const gl_version: [*:0]const u8 = gl.GetString(gl.VERSION).?;
    log.info("Rendering with OpenGL {s}", .{ gl_version });

    // Default winding order is CCW
    gl.Enable(gl.CULL_FACE);

    var renderer: Renderer = .{};

    renderer.createVertexArray();

    return renderer;
}

pub fn deinit(self: Renderer) void {
    // Clean buffers
    gl.DeleteBuffers(1, @ptrCast(&self.vbo));
    gl.DeleteBuffers(1, @ptrCast(&self.ebo));
    gl.DeleteVertexArrays(1, @ptrCast(&self.vao));

    gl.makeProcTableCurrent(null);
}

// ========== Utilities ==========

pub fn adjustViewport(width: i32, height: i32) void {
    gl.Viewport(0, 0, width, height);
}

pub fn setRenderMode(mode: RenderMode) void {
    gl.PolygonMode(gl.FRONT_AND_BACK, switch (mode) {
        .Solid => gl.FILL,
        .Wireframe => gl.LINE,
    });
}

// ========== Object creation ==========

pub fn createVertexArray(self: *Renderer) void {
    const verts = [_]f32{
        // positions        // colors
        -0.5, -0.5, 0.0,    1.0, 1.0, 1.0,  // bottom left
         0.5, -0.5, 0.0,    1.0, 0.0, 0.0,  // bottom right
         0.5,  0.5, 0.0,    0.0, 1.0, 0.0,  // top right
        -0.5,  0.5, 0.0,    0.0, 0.0, 1.0,  // top left
    };
    const indices = [_]gl.uint{
        0, 1, 3,
        1, 2, 3,
    };

    gl.GenVertexArrays(1, @ptrCast(&self.vao));
    gl.GenBuffers(1, @ptrCast(&self.vbo));
    gl.GenBuffers(1, @ptrCast(&self.ebo));

    gl.BindVertexArray(self.vao);

    gl.BindBuffer(gl.ARRAY_BUFFER, self.vbo);
    gl.BufferData(gl.ARRAY_BUFFER, @sizeOf(@TypeOf(verts)), &verts, gl.STATIC_DRAW);

    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, self.ebo);
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, @sizeOf(@TypeOf(indices)), &indices, gl.STATIC_DRAW);

    // position attribute
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 6 * @sizeOf(f32), 0);
    gl.EnableVertexAttribArray(0);
    // color attribute
    gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 6 * @sizeOf(f32), 3 * @sizeOf(f32));
    gl.EnableVertexAttribArray(1);
}

// ========== Render ==========

pub fn render(self: Renderer) void {
    gl.ClearColor(0.0, 0.0, 0.0, 1.0);
    gl.Clear(gl.COLOR_BUFFER_BIT);

    gl.BindVertexArray(self.vao);
    gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, 0);
}
