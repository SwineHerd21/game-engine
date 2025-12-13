const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;

const EngineError = @import("../lib.zig").EngineError;
const io = @import("io.zig");

const math = @import("../math/math.zig");
const Vec3f = math.Vec3f;
const Vec2f = math.Vec2f;

const log = std.log.scoped(.engine);

// TODO: load multiple meshes
// TODO: spit out mesh attributes in separate arrays, make graphics pipeline convert them to GPU meshes
// based on what user wants (no normals or index being u16 instead of u32 for example)
// TODO: load materials

pub const Model = struct {
    meshes: []const MeshData,
    /// Unused for now
    materials: []const []const u8,

    pub fn deinit(self: Model, gpa: Allocator) void {
        for (self.meshes) |m| {
            m.deinit(gpa);
        }
        gpa.free(self.meshes);
        // for (self.materials) |m| {
        //     gpa.free(m);
        // }
        gpa.free(self.materials);
    }
};

/// GPU-friendly mesh data, verticies is in the format (position, normal, texture coordinate)
pub const MeshData = struct {
    verticies: []const Vertex,
    indicies: []const u32,

    pub fn deinit(self: MeshData, gpa: Allocator) void {
        gpa.free(self.verticies);
        gpa.free(self.indicies);
    }
};

pub const Vertex = extern struct {
    position: Vec3f,
    texture_coordinates: Vec2f,
    normal: Vec3f,
};

/// Loads a 3D model from a .obj file. The model may contain multiple meshes and materials
/// in order of appearance in the file.
/// TODO: load materials
pub fn loadModel(gpa: mem.Allocator, path: []const u8) EngineError!Model {
    const text = try io.readFile(gpa, path);
    defer gpa.free(text);

    // there's a lot of array list operations here
    errdefer |err| if (err == error.OutOfMemory) log.err("Out of memory", .{});

    var parse_mode: ParseMode = .Verticies;
    var meshes: std.ArrayList(MeshData) = try .initCapacity(gpa, 1);
    errdefer meshes.deinit(gpa);
    var materials: std.ArrayList([]const u8) = try .initCapacity(gpa, 1);
    errdefer materials.deinit(gpa);

    var positions: std.ArrayList(f32) = try .initCapacity(gpa, 128*3);
    defer positions.deinit(gpa);
    var texture_coords: std.ArrayList(f32) = try .initCapacity(gpa, 128*2);
    defer texture_coords.deinit(gpa);
    var normals: std.ArrayList(f32) = try .initCapacity(gpa, 128*3);
    defer normals.deinit(gpa);

    var faces: std.ArrayList(Face) = try .initCapacity(gpa, 128);
    defer faces.deinit(gpa);

    var lines = mem.splitScalar(u8, text, '\n');
    while (lines.next()) |line| {
        var words = mem.splitScalar(u8, line, ' ');
        const first = words.next() orelse continue;

        var face: Face = undefined;

        if (mem.eql(u8, first, "#")) {
            continue;
        } else if (mem.eql(u8, first, "v")) {
            parse_mode = .Verticies;
            if (iterCountRemaining(&words) != 3) return error.InvalidData;
            _=words.next();
        } else if (mem.eql(u8, first, "vt")) {
            parse_mode = .TextCoords;
            if (iterCountRemaining(&words) != 2) return error.InvalidData;
            _=words.next();
        } else if (mem.eql(u8, first, "vn")) {
            parse_mode = .Normals;
            if (iterCountRemaining(&words) != 3) return error.InvalidData;
            _=words.next();
        } else if (mem.eql(u8, first, "f")) {
            parse_mode = .Faces;

            const vert_count = iterCountRemaining(&words);
            if (vert_count < 3) return error.InvalidData;
            _ = words.next();

            face = .{
                .vert_count = vert_count,
                .verticies = try gpa.alloc([3]usize, vert_count),
            };
        } else if (mem.eql(u8, first, "mtllib")) {
            try materials.append(gpa, words.next() orelse return error.InvalidData);
        } else {
            continue;
        }

        var vert_count: usize = 0;
        while (words.next()) |word| {
            switch (parse_mode) {
                .Verticies => try positions.append(gpa, std.fmt.parseFloat(f32, word) catch return error.InvalidData),
                .TextCoords => try texture_coords.append(gpa, std.fmt.parseFloat(f32, word) catch return error.InvalidData),
                .Normals => try normals.append(gpa, std.fmt.parseFloat(f32, word) catch return error.InvalidData),
                .Faces => {
                    var indicies = mem.splitScalar(u8, word, '/');
                    const vertex: [3]usize = .{
                        std.fmt.parseInt(usize, indicies.next() orelse return error.InvalidData, 10) catch return error.InvalidData,
                        std.fmt.parseInt(usize, indicies.next() orelse return error.InvalidData, 10) catch return error.InvalidData,
                        std.fmt.parseInt(usize, indicies.next() orelse return error.InvalidData, 10) catch return error.InvalidData,
                    };
                    face.verticies[vert_count] = vertex;
                    vert_count += 1;
                },
            }
        }

        if (parse_mode == .Faces) {
            try faces.append(gpa, face);
        }
    }

    // std.debug.print("Positions: {}\n{any}\n", .{positions.items.len/3, positions.items});
    // std.debug.print("TextCoords: {}\n{any}\n", .{texture_coords.items.len/2, texture_coords.items});
    // std.debug.print("Normals: {}\n{any}\n", .{normals.items.len/3, normals.items});
    // std.debug.print("Faces: {}\n", .{faces.items.len});
    // for (faces.items) |f| {
    //     std.debug.print("{any}, ", .{f});
    // }
    // std.debug.print("\n", .{});

    // Translate into GPU compatable format

    var verticies: std.ArrayList(f32) = try .initCapacity(gpa, faces.capacity*(3+3+2)*3);
    errdefer verticies.deinit(gpa);
    var indicies: std.ArrayList(u32) = try .initCapacity(gpa, faces.capacity*3*2);
    errdefer indicies.deinit(gpa);
    var existing: std.ArrayList([3]usize) = try .initCapacity(gpa, faces.capacity*4);
    defer existing.deinit(gpa);

    for (faces.items) |*f| {
        defer f.deinit(gpa);
        for (f.verticies, 1..) |v, i| {
            // i starts with 1 because 0 passes this test
            if (i % 4 == 0) {
                // polygon, start a new triangle
                try indicies.append(gpa, indicies.items[indicies.items.len-3]);
                try indicies.append(gpa, indicies.items[indicies.items.len-2]);
            }

            if (indexOfScalar([3]usize, existing.items, v)) |j| {
                // vertex data combination is stored already
                try indicies.append(gpa, @intCast(j));
            } else {
                try existing.append(gpa, v);

                const pos_offset = (v[0]-1)*3;
                const texture_offset = (v[1]-1)*2;
                const normal_offset = (v[2]-1)*3;

                try verticies.appendSlice(gpa, positions.items[pos_offset..(pos_offset+3)]);
                try verticies.appendSlice(gpa, texture_coords.items[texture_offset..(texture_offset+2)]);
                try verticies.appendSlice(gpa, normals.items[normal_offset..(normal_offset+3)]);
                try indicies.append(gpa, @intCast(existing.items.len - 1));
            }
        }
    }

    try meshes.append(gpa, .{
        .verticies = @ptrCast(try verticies.toOwnedSlice(gpa)),
        .indicies = try indicies.toOwnedSlice(gpa),
    });

    return .{
        .meshes = try meshes.toOwnedSlice(gpa),
        .materials = try materials.toOwnedSlice(gpa),
    };
}

const ParseMode = enum {
    Verticies,
    TextCoords,
    Normals,
    Faces,
};

const Face = struct {
    vert_count: usize,
    verticies: [][3]usize,

    pub fn deinit(self: *Face, gpa: Allocator) void {
        gpa.free(self.verticies);
    }
};

/// `std.mem.indexOfScalar` uses a direct `==` which does not support arrays or custom types.
/// This function uses `std.meta.eql`
/// TODO: place this publically in a namespace where it will make sense
fn indexOfScalar(comptime T: type, haystack: []const T, needle: T) ?usize {
    for (haystack, 0..) |v, i| {
        if (std.meta.eql(v, needle)) {
            return i;
        }
    }
    return null;
}

fn iterCountRemaining(iter: *mem.SplitIterator(u8, .scalar)) usize {
    var i: usize = 0;
    while (iter.next()) |_| i += 1;
    iter.reset();
    return i;
}
