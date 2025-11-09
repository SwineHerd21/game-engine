//! Loads requested assets into caches with string identifiers.

const std = @import("std");

const EngineError = @import("../lib.zig").EngineError;

const Shader = @import("../graphics/Shader.zig");
const Mesh = @import("../graphics/Mesh.zig");

const asset_cache = @import("asset_cache.zig");
const AssetCache = asset_cache.AssetCache;
const OpaqueAssetCache = asset_cache.OpaqueAssetCache;

const AssetManager = @This();

const log = std.log.scoped(.engine);

gpa: std.mem.Allocator,
database: std.StringHashMapUnmanaged(OpaqueAssetCache),

/// Call deinit after
pub fn init(allocator: std.mem.Allocator) AssetManager {
    return .{
        .gpa = allocator,
        .database = .empty,
    };
}

pub fn deinit(self: *AssetManager) void {
    var iter = self.database.valueIterator();
    while (iter.next()) |c| {
        c.deinit(c.*, self.gpa);
    }
    self.database.deinit(self.gpa);
}

// ========== General =========

/// Spits out a slice of the file's entire contents. Call 'free()' you are done using them.
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
    const file_text = self.gpa.alloc(u8, file_stat.size) catch {
        log.err("File '{s}' is too large, could not allocate memory", .{path});
        return EngineError.OutOfMemory;
    };
    errdefer self.gpa.free(file_text);

    _ = file.read(file_text) catch {
        log.err("Could not read file '{s}'", .{path});
        return EngineError.IOError;
    };

    return file_text;
}

pub fn free(self: AssetManager, data: anytype) void {
    self.gpa.free(data);
}

// ========== Cache management ==========

fn createCache(
    self: AssetManager,
    comptime T: type,
    init_fn: fn(data: []const u8, std.mem.Allocator) T,
    deinit_fn: fn(*T, std.mem.Allocator) void,
) EngineError!OpaqueAssetCache {
    const ptr = self.gpa.create(AssetCache(T)) catch return outOfMemory();
    ptr.* = AssetCache(T){
        .hashmap = .empty,
        .init_fn = init_fn,
        .deinit_fn = deinit_fn,
    };
    return .{
        .ptr = @ptrCast(ptr),
        .deinit = (struct {
            pub fn deinit(s: OpaqueAssetCache, alloc: std.mem.Allocator) void {
                const cache = s.cast(T);
                cache.deinit(alloc);
                alloc.destroy(cache);
            }
        }).deinit,
    };
}

fn getCache(self: AssetManager, comptime T: type) !*AssetCache(T) {
    const cache_opaque = self.database.getPtr(@typeName(T)) orelse {
        log.err("Tried to load an asset of unregistered type '{s}'", .{@typeName(T)});
        return EngineError.InvalidAssetType;
    };
    return cache_opaque.cast(T);
}

/// Must be called for any type you wish to use as an asset.
///
/// 'init_fn' should be an initialization function and 'deinit_fn' should be used for any clean up needed.
pub fn registerAssetType(
    self: *AssetManager,
    comptime T: type,
    init_fn: fn(data: []const u8, std.mem.Allocator) T,
    deinit_fn: fn(*T, std.mem.Allocator) void,
) EngineError!void {
    const name = @typeName(T);
    const entry = self.database.getOrPut(self.gpa, name) catch return outOfMemory();
    if (entry.found_existing) {
        log.warn("Tried to re-register asset type '{s}'", .{name});
        return;
    }

    entry.value_ptr.* = try self.createCache(T, init_fn, deinit_fn);
    log.info("Registered asset type '{s}'", .{name});
}

// ========== Interface ==========

/// Get a pointer to an existing asset, or load it from file if it is not cached.
pub fn getPtr(self: *AssetManager, comptime T: type, filepath: []const u8) EngineError!*T {
    const realpath = try self.getRealpath(filepath);
    errdefer self.gpa.free(realpath);

    const cache = try self.getCache(T);

    const asset_entry = cache.hashmap.getOrPut(self.gpa, realpath) catch return outOfMemory();
    errdefer _=cache.hashmap.remove(realpath);
    if (!asset_entry.found_existing) {
        asset_entry.value_ptr.* = try self.loadToCache(T, cache.*, realpath);
        log.debug("Loaded asset '{s}' of type '{s}'", .{filepath, @typeName(T)});
    }

    return asset_entry.value_ptr;
}

pub fn get(self: *AssetManager, comptime T: type, filepath: []const u8) EngineError!T {
    return (try self.getPtr(T, filepath)).*;
}


pub fn getPtrNamed(self: *AssetManager, comptime T: type, name: []const u8) EngineError!?*T {
    const cache = try self.getCache(T);
    return cache.hashmap.getPtr(name);
}

pub fn getNamed(self: *AssetManager, comptime T: type, name: []const u8) EngineError!?T {
    const cache = try self.getCache(T);
    return cache.hashmap.get(name);
}

fn loadToCache(self: AssetManager, comptime T: type, cache: AssetCache(T), filepath: []const u8) EngineError!T {
    const data = try self.readFile(filepath);
    return cache.init_fn(data, self.gpa);
}

/// Put a pre-initialized asset into the database. Access with 'getNamed()' and 'getPtrNamed()'.
pub fn put(self: *AssetManager, name: []const u8, value: anytype) EngineError!void {
    const T = @TypeOf(value);
    const cache = try self.getCache(T);
    cache.hashmap.put(self.gpa, name, value) catch return outOfMemory();
    log.debug("Added named asset '{s}' of type '{s}'", .{name, @typeName(T)});
}

// ========== Helpers ==========

fn getRealpath(self: AssetManager, path: []const u8) EngineError![]const u8 {
    return std.fs.cwd().realpathAlloc(self.gpa, path) catch |err| switch (err) {
        error.OutOfMemory => return outOfMemory(),
        else => {
            log.err("Could not locate file '{s}'", .{path});
            return EngineError.IOError;
        },
    };
}

inline fn outOfMemory() EngineError {
    log.err("Out of memory", .{});
    return EngineError.OutOfMemory;
}
