//! Loads requested assets into caches with string identifiers.

const std = @import("std");

const EngineError = @import("../lib.zig").EngineError;

const Shader = @import("../graphics/Shader.zig");
const Mesh = @import("../graphics/Mesh.zig");

const AssetManager = @This();

const log = std.log.scoped(.engine);

gpa: std.mem.Allocator,
asset_folder: []const u8,
shader_cache: std.StringHashMapUnmanaged(Shader),
mesh_cache: std.StringHashMapUnmanaged(Mesh),

/// Call deinit after
pub fn init(allocator: std.mem.Allocator, asset_folder: []const u8) AssetManager {
    return .{
        .gpa = allocator,
        .asset_folder = asset_folder,
        .shader_cache = .empty,
        .mesh_cache = .empty,
    };
}

pub fn deinit(self: *AssetManager) void {
    inline for (@typeInfo(AssetManager).@"struct".fields[2..]) |f| {
        var cache = @field(self, f.name);
        var iter = cache.valueIterator();
        while (iter.next()) |a| {
            a.*.destroy();
        }
        cache.deinit(self.gpa);
    }
}

// ========== General =========

/// Spits out a slice of the file's entire contents. Call it you are done using them.
pub fn readFile(self: AssetManager, path: []const u8) EngineError![]const u8 {
    const full_path = std.mem.concat(self.gpa, u8, &.{self.asset_folder, path}) catch return EngineError.OutOfMemory;
    const file = std.fs.cwd().openFile(full_path, .{}) catch {
        log.err("File '{s}' does not exist or is inaccessible", .{full_path});
        return EngineError.IOError;
    };
    defer file.close();
    const file_stat = file.stat() catch {
        log.err("File '{s}' is likely corrupted", .{full_path});
        return EngineError.IOError;
    };
    const file_text = self.gpa.alloc(u8, file_stat.size) catch {
        log.err("File '{s}' is too large, could not allocate memory", .{full_path});
        return EngineError.OutOfMemory;
    };

    _ = file.read(file_text) catch {
        log.err("Could not read file '{s}'", .{full_path});
        return EngineError.IOError;
    };

    return file_text;
}

// ========== Assets ==========

// TODO: make paths relative to an asset folder supplied by library user

pub fn getShader(self: AssetManager, name: []const u8) ?Shader {
    return self.shader_cache.get(name);
    // return if (self.shader_cache.get(name)) |p| p.* else null;
}

pub fn loadShader(self: *AssetManager, name: []const u8, vertex_file: []const u8, fragment_file: []const u8) EngineError!void {
    errdefer log.err("Could not create shader '{s}' from files '{s}' and '{s}'", .{name, vertex_file, fragment_file});

    const vertex_code = try self.readFile(vertex_file);
    const fragment_code = try self.readFile(fragment_file);

    // const shader = self.gpa.create(Shader) catch return outOfMemory();
    const shader = try Shader.create(vertex_code, fragment_code);
    const name_owned = self.gpa.dupe(u8, name) catch return outOfMemory();

    self.shader_cache.put(self.gpa, name_owned, shader) catch return outOfMemory();

    log.debug("Loaded shader '{s}'", .{name});
}

pub fn getMesh(self: AssetManager, name: []const u8) ?Mesh {
    return self.mesh_cache.get(name);
    // return if (self.mesh_cache.get(name)) |p| p.* else null;
}

pub fn loadMeshTemp(self: *AssetManager, name: []const u8, vertices: []const f32, indices: []const c_uint) EngineError!void {
    // const mesh = self.gpa.create(Mesh) catch return outOfMemory();
    const mesh = Mesh.create(vertices, indices);
    const name_owned = self.gpa.dupe(u8, name) catch return outOfMemory();

    self.mesh_cache.put(self.gpa, name_owned, mesh) catch return outOfMemory();

    log.debug("Loaded mesh '{s}'", .{name_owned});
}

inline fn outOfMemory() EngineError {
    log.err("Out of memory", .{});
    return EngineError.OutOfMemory;
}
