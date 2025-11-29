//! Holds a VAO, VBO, EBO, etc.

const std = @import("std");
const gl = @import("gl");

const Allocator = std.mem.Allocator;
const AssetManager = @import("../assets/AssetManager.zig");
const Material = @import("Material.zig");

const Mesh = @This();

vao: gl.uint,
buffer: gl.uint,
ibo: gl.uint,
index_count: gl.int,

pub fn init(verticies: []const f32, indices: []const u32) Mesh {
    var mesh: Mesh = .{
        .vao = undefined,
        .buffer = undefined,
        .ibo = undefined,
        .index_count = @intCast(@as(gl.uint, @truncate(indices.len))),
    };

    const vert_size = @as(isize, @intCast(verticies.len)) * @sizeOf(f32);
    const ind_size = @as(isize, @intCast(indices.len)) * @sizeOf(u32);

    // https://github.com/fendevel/Guide-to-Modern-OpenGL-Functions

    gl.CreateBuffers(1, @ptrCast(&mesh.buffer));
    gl.NamedBufferStorage(mesh.buffer, vert_size, verticies.ptr, gl.DYNAMIC_STORAGE_BIT);

    gl.CreateBuffers(1, @ptrCast(&mesh.ibo));
    gl.NamedBufferStorage(mesh.ibo, ind_size, indices.ptr, gl.DYNAMIC_STORAGE_BIT);

    gl.CreateVertexArrays(1, @ptrCast(&mesh.vao));
    // 3 positions + 2 uvs
    gl.VertexArrayVertexBuffer(mesh.vao, 0, mesh.buffer, 0, 5 * @sizeOf(f32));
    gl.VertexArrayElementBuffer(mesh.vao, mesh.ibo);

    gl.EnableVertexArrayAttrib(mesh.vao, 0);
    gl.EnableVertexArrayAttrib(mesh.vao, 1);

    // position attribute
    gl.VertexArrayAttribFormat(mesh.vao, 0, 3, gl.FLOAT, gl.FALSE, 0);
    // uv attribute
    gl.VertexArrayAttribFormat(mesh.vao, 1, 2, gl.FLOAT, gl.FALSE, 3);

    gl.VertexArrayAttribBinding(mesh.vao, 0, 0);
    gl.VertexArrayAttribBinding(mesh.vao, 1, 0);

    return mesh;
}

pub fn deinit(self: *Mesh, _: @import("std").mem.Allocator) void {
    gl.DeleteBuffers(1, @ptrCast(&self.buffer));
    gl.DeleteBuffers(1, @ptrCast(&self.ibo));
    gl.DeleteVertexArrays(1, @ptrCast(&self.vao));
}

pub fn draw(self: Mesh, material: Material) void {
    material.use();
    gl.BindVertexArray(self.vao);
    gl.DrawElements(gl.TRIANGLES, self.index_count, gl.UNSIGNED_INT, 0);
}
