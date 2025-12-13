const std = @import("std");
const zigimg = @import("zigimg");

const Allocator = std.mem.Allocator;

const EngineError = @import("../lib.zig").EngineError;
const Texture = @import("../graphics/Texture.zig");
const Shader = @import("../graphics/Shader.zig");
const Material = @import("../graphics/Material.zig");

const log = std.log.scoped(.engine);

pub const loadModel = @import("obj_import.zig").loadModel;

/// Spits out a slice of the file's entire contents. Caller owns the data.
pub fn readFile(gpa: Allocator, path: []const u8) EngineError![]const u8 {
    // 50 MiB should be enough for most things
    const max_bytes = 50 * 1024*1024;
    return std.fs.cwd().readFileAlloc(gpa, path, 1024*1024*50) catch |err| switch (err) {
        error.OutOfMemory => outOfMemory(),
        error.FileTooBig => {
            log.err("File '{s}' is too big, can read maximum of {} bytes", .{path, max_bytes});
            return error.IOError;
        },
        else => {
            log.err("Could not read file '{s}'", .{path});
            return error.IOError;
        },
    };
}

// TODO: make custom image type that plays nicely with Texture pixel formats?
//       or just make a function to translate them

/// Set `flip_vertically` if you will pass the image to OpenGL or call `image.flipVertically()`
pub fn loadImage(gpa: Allocator, path: []const u8, flip_vertically: bool) EngineError!zigimg.Image {
    var buf: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var image = zigimg.Image.fromFilePath(gpa, path, buf[0..]) catch |err| switch (err) {
        error.OutOfMemory => return outOfMemory(),
        error.Unsupported, error.InvalidData => {
            log.err("Image file '{s}' contains an invalid format", .{path});
            return error.IOError;
        },
        else => {
            log.err("File '{s}' is inaccessible or invalid", .{path});
            return error.IOError;
        },
    };

    if (flip_vertically) image.flipVertically(gpa) catch return error.OutOfMemory;

    // if (image.pixelFormat() != .rgba32) {
    //     image.convert(gpa, .rgba32) catch {
    //         // Zigimg calls the 4-channel-of-8-bits format rgba32 instead of rgba8
    //         log.err("Could not convert image to rgba8", .{});
    //         return error.AssetLoadError;
    //     };
    // }

    return image;
}

pub fn loadShader(gpa: Allocator, path: []const u8, shader_type: Shader.Type) EngineError!Shader {
    const file = try readFile(gpa, path);
    defer gpa.free(file);

    return Shader.init(file, shader_type);
}

/// Helper function for parsing a ZON file into a specific type
pub fn parseZon(gpa: Allocator, comptime T: type, file: []const u8) error{OutOfMemory, ParseZon}!T {
    const data = try readFile(gpa, file);
    defer gpa.free(data);

    var diag: std.zon.parse.Diagnostics = .{};
    const data_z = gpa.dupeZ(u8, data) catch return outOfMemory();
    defer gpa.free(data_z);
    const value = std.zon.parse.fromSlice(T, gpa, @ptrCast(data_z), &diag, .{}) catch |err| switch (err) {
        error.OutOfMemory => return outOfMemory(),
        else => {
            log.err("Failed to parse ZON file: {f}", .{diag});
            return error.ParseZon;
        },
    };

    return value;
}

inline fn outOfMemory() error{OutOfMemory} {
    @branchHint(.cold);
    log.err("Out of memory", .{});
    return error.OutOfMemory;
}
