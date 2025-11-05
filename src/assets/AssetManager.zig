//! Loads requested assets into caches with string identifiers.

const std = @import("std");

const EngineError = @import("../lib.zig").EngineError;

const Shader = @import("../rendering/Shader.zig");
const Mesh = @import("../rendering/Mesh.zig");

const AssetManager = @This();

const log = std.log.scoped(.engine);

allocator: std.mem.Allocator,
shader_cache: std.StringHashMapUnmanaged(Shader),
mesh_cache: std.StringHashMapUnmanaged(Mesh),

/// Call deinit after
pub fn init(allocator: std.mem.Allocator) AssetManager {
    return .{
        .allocator = allocator,
        .shader_cache = .empty,
        .mesh_cache = .empty,
    };
}

pub fn deinit(self: *AssetManager) void {
    var shader_iter = self.shader_cache.valueIterator();
    while (shader_iter.next()) |s| {
        s.destroy();
    }

    self.shader_cache.clearAndFree(self.allocator);
    self.shader_cache.deinit(self.allocator);

    self.mesh_cache.clearAndFree(self.allocator);
    self.mesh_cache.deinit(self.allocator);
}

// ========== General =========

/// Spits out a slice of the file's entire contents. Call free it you are done using them.
pub fn readFile(self: AssetManager, path: []const u8) EngineError![]const u8 {
    const file = std.fs.cwd().openFile(path, .{}) catch {
        log.err("File '{s}' does not exist or is inaccessible", .{path});
        return EngineError.IOError;
    };
    defer file.close();
    const file_stat = file.stat() catch {
        log.err("File '{s}' is likely corrupted", .{path});
        return EngineError.IOError;
    };
    const file_text = self.allocator.alloc(u8, file_stat.size) catch {
        log.err("File '{s}' is too large, could not allocate memory", .{path});
        return EngineError.OutOfMemory;
    };

    _ = file.read(file_text) catch {
        log.err("Could not read file '{s}'", .{path});
        return EngineError.IOError;
    };

    return file_text;
}

/// Only free memory loaded with the AssetManager itself.
pub fn free(self: AssetManager, memory: anytype) void {
    self.allocator.free(memory);
}

// ========== Assets ==========

// TODO: make paths relative to an asset folder supplied by library user

/// Get an asset from the cache or load it from a file on disk.
pub fn getShader(self: AssetManager, name: []const u8) ?Shader {
    return self.shader_cache.get(name);
}

pub fn loadShader(self: *AssetManager, name: []const u8, vertex_file: []const u8, fragment_file: []const u8) EngineError!void {
    errdefer log.err("Could not create shader '{s}' from files '{s}' and '{s}'", .{name, vertex_file, fragment_file});

    const vertex_code = try self.readFile(vertex_file);
    defer self.free(vertex_code);
    const fragment_code = try self.readFile(fragment_file);
    defer self.free(fragment_code);

    const shader = try Shader.create(vertex_code, fragment_code);
    self.shader_cache.put(self.allocator, name, shader) catch {
        log.err("Out of memory", .{});
        return EngineError.OutOfMemory;
    };
}

