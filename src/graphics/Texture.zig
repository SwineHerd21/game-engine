const std = @import("std");
const gl = @import("gl");
const zigimg = @import("zigimg");

const AssetManager = @import("../assets/AssetManager.zig");
const EngineError = @import("../lib.zig").EngineError;

const log = std.log.scoped(.engine);

const Texture = @This();

handle: gl.uint,

pub fn init(data: []const u8, assets: *AssetManager) EngineError!Texture {
    var image = zigimg.Image.fromMemory(assets.gpa, data) catch |err| switch (err) {
        error.OutOfMemory => return EngineError.OutOfMemory,
        else => return EngineError.AssetLoadError,
    };
    image.flipVertically(assets.gpa) catch return EngineError.OutOfMemory;
    defer image.deinit(assets.gpa);
    if (image.pixelFormat() != .rgba32) {
        image.convert(assets.gpa, .rgba32) catch {
            log.err("Could not convert image to rgba32", .{});
            return EngineError.AssetLoadError;
        };
    }

    var texture: gl.uint = undefined;
    gl.GenTextures(1, @ptrCast(&texture));
    gl.BindTexture(gl.TEXTURE_2D, texture);

    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, @intCast(image.width), @intCast(image.height), 0, gl.RGBA, gl.UNSIGNED_BYTE, image.pixels.rgba32.ptr);
    gl.GenerateMipmap(gl.TEXTURE_2D);

    return .{
        .handle = texture,
    };
}

pub fn deinit(self: *Texture, _: std.mem.Allocator) void {
    gl.DeleteTextures(1, @ptrCast(&self.handle));
}
