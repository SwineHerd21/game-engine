//! Holds a VAO, VBO, EBO, etc.

const gl = @import("gl");

const Shader = @import("Shader.zig");

const Mesh = @This();

vao: gl.uint,
vbo: gl.uint,
ebo: gl.uint,
index_count: gl.int,

pub fn init(vertices: []const f32, indices: []const u32) Mesh {
    var mesh: Mesh = .{
        .vao = undefined,
        .vbo = undefined,
        .ebo = undefined,
        .index_count = @intCast(@as(gl.uint, @truncate(indices.len))),
    };

    gl.GenVertexArrays(1, @ptrCast(&mesh.vao));
    gl.GenBuffers(1, @ptrCast(&mesh.vbo));
    gl.GenBuffers(1, @ptrCast(&mesh.ebo));

    gl.BindVertexArray(mesh.vao);
    defer gl.BindVertexArray(0);

    gl.BindBuffer(gl.ARRAY_BUFFER, mesh.vbo);
    gl.BufferData(gl.ARRAY_BUFFER, @as(isize, @intCast(vertices.len)) * @sizeOf(f32), vertices.ptr, gl.STATIC_DRAW);

    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, mesh.ebo);
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, @as(isize, @intCast(indices.len)) * @sizeOf(gl.uint), indices.ptr, gl.STATIC_DRAW);

    // position attribute
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 6 * @sizeOf(f32), 0);
    gl.EnableVertexAttribArray(0);
    // color attribute
    gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 6 * @sizeOf(f32), 3 * @sizeOf(f32));
    gl.EnableVertexAttribArray(1);

    return mesh;
}

pub fn deinit(self: *Mesh, _: @import("std").mem.Allocator) void {
    gl.DeleteBuffers(1, @ptrCast(&self.vbo));
    gl.DeleteBuffers(1, @ptrCast(&self.ebo));
    gl.DeleteVertexArrays(1, @ptrCast(&self.vao));
}

pub fn draw(self: Mesh, shader: Shader) void {
    shader.use();
    gl.BindVertexArray(self.vao);
    gl.DrawElements(gl.TRIANGLES, self.index_count, gl.UNSIGNED_INT, 0);
}
