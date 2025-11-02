const std = @import("std");
const gl = @import("gl");

const native = @import("platform.zig").native;
const Window = @import("../Window.zig");

const Renderer = @This();

// OpenGL runtime loaded functions
var procs: gl.ProcTable = undefined;


vbo: gl.uint,

/// Call deinit at the end
pub fn init() Renderer {
    // Load OpenGL functions
    if (!procs.init(native.getProcAddress)) return error.InitFailed;
    gl.makeProcTableCurrent(&procs);

    // Default winding order is CCW
    gl.Enable(gl.CULL_FACE);

    return .{
        .vbo = undefined,
    };
}

pub fn deinit(self: Renderer) void {
    gl.makeProcTableCurrent(null);
    _ = self;
}

pub fn createVertexBuffer(self: *Renderer) void {
    const verts = [_]f32{
        -1.0, -1.0, 0.0,    // bottom left
        1.0, -1.0, 0.0,     // bottom right
        0.0, 1.0, 0.0,      // top
    };

    gl.GenBuffers(1, @ptrCast(&self.vbo));
    gl.BindBuffer(gl.ARRAY_BUFFER, self.vbo);
    gl.BufferData(gl.ARRAY_BUFFER, @sizeOf(@TypeOf(verts)), &verts, gl.STATIC_DRAW);
}

pub fn render(self: Renderer, window: Window) void {
    gl.Clear(gl.COLOR_BUFFER_BIT);

    gl.BindBuffer(gl.ARRAY_BUFFER, self.vbo);

    gl.EnableVertexAttribArray(0);
    defer gl.DisableVertexAttribArray(0);
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 0, 0);

    gl.DrawArrays(gl.TRIANGLES, 0, 3);

    window.swapBuffers();
}
