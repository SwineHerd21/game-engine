const std = @import("std");
const gl = @import("gl");

const Window = @import("../Window.zig");

const Renderer = @This();


vbo: gl.uint,

/// Call deinit after
pub fn init() Renderer {
    // Default winding order is CCW
    gl.Enable(gl.CULL_FACE);

    return .{
        .vbo = undefined,
    };
}

pub fn deinit(self: Renderer) void {
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
