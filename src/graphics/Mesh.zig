//! Holds a VAO, VBO, EBO, etc.

const std = @import("std");
const gl = @import("gl");

const Allocator = std.mem.Allocator;
const AssetManager = @import("../assets/AssetManager.zig");
const Material = @import("Material.zig");

const Mesh = @This();

vao: gl.uint,
vbo: gl.uint,
ebo: gl.uint,
index_count: gl.int,

pub fn init(positions: []const f32, uv: []const f32, indices: []const u32) Mesh {
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

    const pos_size = @as(isize, @intCast(positions.len)) * @sizeOf(f32);
    const uv_size = @as(isize, @intCast(uv.len)) * @sizeOf(f32);
    const ind_size = @as(isize, @intCast(indices.len)) * @sizeOf(u32);

    gl.BindBuffer(gl.ARRAY_BUFFER, mesh.vbo);
    gl.BufferData(gl.ARRAY_BUFFER, pos_size + uv_size, null, gl.STATIC_DRAW);
    gl.BufferSubData(gl.ARRAY_BUFFER, 0, pos_size, positions.ptr);
    gl.BufferSubData(gl.ARRAY_BUFFER, pos_size, uv_size, uv.ptr);

    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, mesh.ebo);
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, ind_size, indices.ptr, gl.STATIC_DRAW);

    // position attribute
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * @sizeOf(f32), 0);
    gl.EnableVertexAttribArray(0);
    // uv attribute
    gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 2 * @sizeOf(f32), @intCast(pos_size));
    gl.EnableVertexAttribArray(1);

    return mesh;
}

pub fn deinit(self: *Mesh, _: @import("std").mem.Allocator) void {
    gl.DeleteBuffers(1, @ptrCast(&self.vbo));
    gl.DeleteBuffers(1, @ptrCast(&self.ebo));
    gl.DeleteVertexArrays(1, @ptrCast(&self.vao));
}

pub fn draw(self: Mesh, material: Material) void {
    material.use();
    gl.BindVertexArray(self.vao);
    gl.DrawElements(gl.TRIANGLES, self.index_count, gl.UNSIGNED_INT, 0);
}
