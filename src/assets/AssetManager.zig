//! Loads requested assets into caches with string identifiers.
//!
//! Getting an asset is somewhat expensive, especially if it has not been loaded yet,
//! so it is recommended to get an asset once and store a reference to it.

// TODO: consider switching to UUIDs stored in meta files which map to file paths

const std = @import("std");

const EngineError = @import("../lib.zig").EngineError;

const asset_cache = @import("asset_cache.zig");
const AssetCache = asset_cache.AssetCache;
const OpaqueAssetCache = asset_cache.OpaqueAssetCache;

const AssetManager = @This();

const log = std.log.scoped(.engine);

gpa: std.mem.Allocator,
asset_folder: []const u8,
database: std.StringHashMapUnmanaged(OpaqueAssetCache),

/// Call deinit after
pub fn init(allocator: std.mem.Allocator, asset_folder: []const u8) AssetManager {
    return .{
        .gpa = allocator,
        .asset_folder = asset_folder,
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

/// Spits out a slice of the file's entire contents. Call `free()` you are done using them.
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
    init_fn: fn(data: []const u8, *AssetManager) anyerror!T,
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
/// `init_fn` should be an initialization function and `deinit_fn` should be used for any clean up needed.
pub fn registerAssetType(
    self: *AssetManager,
    comptime T: type,
    init_fn: fn(data: []const u8, *AssetManager) anyerror!T,
    deinit_fn: fn(*T, std.mem.Allocator) void,
) EngineError!void {
    const name = @typeName(T);
    const entry = self.database.getOrPut(self.gpa, name) catch return outOfMemory();
    if (entry.found_existing) {
        log.warn("Tried to re-register asset type '{s}'", .{name});
        return;
    }

    entry.value_ptr.* = try self.createCache(T, init_fn, deinit_fn);
    log.debug("Registered asset type '{s}'", .{name});
}

// ========== Interface ==========

/// Load an asset into memory.
pub fn load(self: *AssetManager, comptime T: type, filepath: []const u8) EngineError!void {
    const cache = try self.getCache(T);

    const canon_path = try self.getCanonicalPath(filepath);
    errdefer self.gpa.free(canon_path);

    const asset = self.createAsset(T, cache.*, canon_path) catch {
        log.err("Failed to load asset '{s}' of type '{s}'", .{canon_path, @typeName(T)});
        return EngineError.AssetLoadError;
    };
    cache.hashmap.put(self.gpa, canon_path, asset) catch return outOfMemory();
    log.debug("Loaded asset '{s}' of type '{s}'", .{canon_path, @typeName(T)});
}

/// Load a batch of assets into memory at once. If any asset could not be loaded returns an error after finishing.
/// If the engine runs out of memory the function will exit early
pub fn loadBatch(self: *AssetManager, comptime T: type, files: []const []const u8) EngineError!void {
    const cache = try self.getCache(T);

    var fail = false;
    for (files, 0..files.len) |filepath, _| {
        const canon_path = try self.getCanonicalPath(filepath);
        errdefer self.gpa.free(canon_path);

        const asset = self.createAsset(T, cache.*, canon_path) catch {
            log.err("Failed to load asset '{s}' of type '{s}'", .{canon_path, @typeName(T)});
            fail = true;
            continue;
        };
        // being out of memory is probably a good reason to quit entirely
        cache.hashmap.put(self.gpa, canon_path, asset) catch return outOfMemory();
        log.debug("Loaded asset '{s}' of type '{s}'", .{canon_path, @typeName(T)});
    }
    if (fail) return EngineError.AssetLoadError;
}

/// Get a pointer to an existing asset, or load it from file if it is not cached.
/// This function is slow so it is recommended to cache the result.
pub fn getOrLoadPtr(self: *AssetManager, comptime T: type, filepath: []const u8) EngineError!*T {
    const cache = try self.getCache(T);

    const canon_path = try self.getCanonicalPath(filepath);
    errdefer self.gpa.free(canon_path);

    const asset_entry = cache.hashmap.getOrPut(self.gpa, canon_path) catch return outOfMemory();
    errdefer _=cache.hashmap.remove(canon_path);
    if (!asset_entry.found_existing) {
        asset_entry.value_ptr.* = self.createAsset(T, cache.*, canon_path) catch {
            log.err("Failed to load asset '{s}' of type '{s}'", .{canon_path, @typeName(T)});
            return EngineError.AssetLoadError;
        };
        log.debug("Loaded asset '{s}' of type '{s}'", .{canon_path, @typeName(T)});
    }

    return asset_entry.value_ptr;
}

/// Get a copy of an existing asset, or load it from file if it is not cached.
/// This function is slow so it is recommended to cache the result.
pub fn getOrLoad(self: *AssetManager, comptime T: type, filepath: []const u8) EngineError!T {
    return (try self.getOrLoadPtr(T, filepath)).*;
}

/// Get a pointer to an asset if it is loaded.
/// This function is slow so it is recommended to cache the result.
pub fn getPtr(self: AssetManager, comptime T: type, filepath: []const u8) ?*T {
    const cache = self.getCache(T) catch return gotUnregistered(T);

    const canon_path = self.getCanonicalPath(filepath) catch return null;
    defer self.gpa.free(canon_path);

    return cache.hashmap.getPtr(canon_path);
}

/// Get a copy of an asset if it is loaded.
/// This function is slow so it is recommended to cache the result.
pub fn get(self: AssetManager, comptime T: type, filepath: []const u8) ?T {
    const cache = self.getCache(T) catch return gotUnregistered(T);
    const canon_path = self.getCanonicalPath(filepath) catch return null;
    defer self.gpa.free(canon_path);

    return cache.hashmap.get(canon_path);
}

fn createAsset(self: *AssetManager, comptime T: type, cache: AssetCache(T), filepath: []const u8) EngineError!T {
    const data = try self.readFile(filepath);
    defer self.gpa.free(data);
    return cache.init_fn(data, self) catch {
        log.err("Could not initialize asset '{s}'", .{filepath});
        return EngineError.AssetLoadError;
    };
}

/// Put a pre-initialized asset into the database. Access with `getNamed()` and `getPtrNamed()`.
/// If an asset with the same name is already loaded returns `AssetLoadError`
pub fn put(self: *AssetManager, name: []const u8, value: anytype) EngineError!void {
    const T = @TypeOf(value);
    const cache = try self.getCache(T);
    const entry = cache.hashmap.getOrPut(self.gpa, name) catch return outOfMemory();
    if (entry.found_existing) return EngineError.AssetLoadError;
    entry.value_ptr.* = value;
    log.debug("Added named asset '{s}' of type '{s}'", .{name, @typeName(T)});
}

/// Get a pointer to an asset added with `put()` if it is loaded
pub fn getPtrNamed(self: *AssetManager, comptime T: type, name: []const u8) ?*T {
    const cache = self.getCache(T) catch return gotUnregistered(T);
    return cache.hashmap.getPtr(name);
}

/// Get a copy of an asset added with `put()` if it is loaded
pub fn getNamed(self: *AssetManager, comptime T: type, name: []const u8) ?T {
    const cache = self.getCache(T) catch return gotUnregistered(T);
    return cache.hashmap.get(name);
}

// ========== Helpers ==========

/// Helper function for parsing a ZON file into a specific type
pub fn parseZon(self: AssetManager, comptime T: type, data: []const u8) EngineError!T {
    var diag: std.zon.parse.Diagnostics = .{};
    const data_z = self.gpa.dupeZ(u8, data) catch return outOfMemory();
    defer self.gpa.free(data_z);
    const value = std.zon.parse.fromSlice(T, self.gpa, @ptrCast(data_z), &diag, .{}) catch |err| switch (err) {
        error.OutOfMemory => {
            log.err("Out of memory", .{});
            return EngineError.OutOfMemory;
        },
        else => {
            log.err("Invalid ZON file: {f}", .{diag});
            return EngineError.AssetLoadError;
        },
    };

    return value;
}

/// Resolves the path to the asset inside the asset folder relative to cwd
fn getCanonicalPath(self: AssetManager, path: []const u8) EngineError![]const u8 {
    const here_path = std.mem.concat(self.gpa, u8, &.{"./", path}) catch return outOfMemory();
    defer self.gpa.free(here_path);
    return std.fs.path.resolve(self.gpa, &.{self.asset_folder, here_path}) catch return outOfMemory();
}

inline fn outOfMemory() EngineError {
    log.err("Out of memory", .{});
    return EngineError.OutOfMemory;
}

inline fn gotUnregistered(comptime T: type) @TypeOf(null) {
    log.err("Tried to get unregistered asset type '{s}'", .{@typeName(T)});
    return null;
}

// ========== Tests ==========

test "Create cache" {
    const Material = @import("../graphics/Material.zig");
    var assets = AssetManager.init(std.testing.allocator_instance.allocator(), "");
    defer assets.deinit();

    try assets.registerAssetType(Material, Material.init, Material.deinit);
}

test "Get cache" {
    const Material = @import("../graphics/Material.zig");
    var assets = AssetManager.init(std.testing.allocator_instance.allocator(), "");
    defer assets.deinit();
    try assets.registerAssetType(Material, Material.init, Material.deinit);

    const cache = try assets.getCache(Material);
    try std.testing.expectEqual(AssetCache(Material), @TypeOf(cache.*));
}

test "Load material" {
    const Material = @import("../graphics/Material.zig");
    const stub = struct {
        pub fn init(_:[]const u8,_:*AssetManager) !Material{
            return std.mem.zeroes(Material);
        }
        pub fn deinit(_:*Material,_:std.mem.Allocator)void{}
    };
    var assets = AssetManager.init(std.testing.allocator_instance.allocator(), "examples/shader/assets");
    defer assets.deinit();
    try assets.registerAssetType(Material, stub.init, stub.deinit);

    try assets.load(Material, "default.mat");
}
