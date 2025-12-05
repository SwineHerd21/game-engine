const std = @import("std");
const zigimg = @import("zigimg");

const Allocator = std.mem.Allocator;

const EngineError = @import("../lib.zig").EngineError;
const Texture = @import("../graphics/Texture.zig");
const Shader = @import("../graphics/Shader.zig");
const Material = @import("../graphics/Material.zig");

const log = std.log.scoped(.engine);

/// Spits out a slice of the file's entire contents. Caller owns the data.
pub fn readFile(alloc: Allocator, path: []const u8) EngineError![]const u8 {
    const file = std.fs.cwd().openFile(path, .{}) catch {
        log.err("File '{s}' does not exist or is inaccessible", .{path});
        return EngineError.IOError;
    };
    defer file.close();
    const file_stat = file.stat() catch {
        log.err("File '{s}' is likely corrupted", .{path});
        return EngineError.IOError;
    };
    const file_text = alloc.alloc(u8, file_stat.size) catch {
        log.err("File '{s}' is too large, could not allocate memory", .{path});
        return EngineError.OutOfMemory;
    };
    errdefer alloc.free(file_text);

    var reader = file.reader(file_text);
    _ = reader.interface.readSliceShort(file_text) catch {
        log.err("Could not read file {s}", .{path});
        return EngineError.IOError;
    };

    return file_text;
}

pub fn loadTexture(alloc: Allocator, path: []const u8) EngineError!Texture {
    var buf: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var image = zigimg.Image.fromFilePath(alloc, path, buf[0..]) catch |err| switch (err) {
        error.OutOfMemory => return outOfMemory(),
        error.Unsupported, error.InvalidData => {
            log.err("Image file '{s}' contains an invalid format", .{path});
            return EngineError.AssetLoadError;
        },
        else => {
            log.err("File '{s}' is inaccessible or invalid", .{path});
            return EngineError.IOError;
        },
    };
    defer image.deinit(alloc);

    image.flipVertically(alloc) catch return EngineError.OutOfMemory;
    if (image.pixelFormat() != .rgba32) {
        image.convert(alloc, .rgba32) catch {
            log.err("Could not convert image to rgba32", .{});
            return EngineError.AssetLoadError;
        };
    }

    return Texture.init(image.rawBytes(), image.width, image.height);
}

pub fn loadShader(alloc: Allocator, path: []const u8, shader_type: Shader.Type) EngineError!Shader {
    const file = try readFile(alloc, path);
    defer alloc.free(file);

    return Shader.init(file, shader_type);
}

/// Helper function for parsing a ZON file into a specific type
pub fn parseZon(alloc: Allocator, comptime T: type, file: []const u8) error{OutOfMemory, ParseZon}!T {
    const data = try readFile(alloc, file);
    defer alloc.free(data);

    var diag: std.zon.parse.Diagnostics = .{};
    const data_z = alloc.dupeZ(u8, data) catch return outOfMemory();
    defer alloc.free(data_z);
    const value = std.zon.parse.fromSlice(T, alloc, @ptrCast(data_z), &diag, .{}) catch |err| switch (err) {
        error.OutOfMemory => return outOfMemory(),
        else => {
            log.err("Failed to parse ZON file: {f}", .{diag});
            return error.ParseZon;
        },
    };

    return value;
}

inline fn outOfMemory() EngineError {
    @branchHint(.cold);
    log.err("Out of memory", .{});
    return EngineError.OutOfMemory;
}
