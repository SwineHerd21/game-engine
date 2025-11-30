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
    gl.CreateTextures(gl.TEXTURE_2D, 1, @ptrCast(&texture));

    gl.TextureParameteri(texture, gl.TEXTURE_WRAP_S, gl.REPEAT);
    gl.TextureParameteri(texture, gl.TEXTURE_WRAP_T, gl.REPEAT);
    gl.TextureParameteri(texture, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.TextureParameteri(texture, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

    const w: gl.sizei = @intCast(image.width);
    const h: gl.sizei = @intCast(image.height);
    gl.TextureStorage2D(texture, 1, gl.RGBA8, w, h);
    gl.TextureSubImage2D(texture, 0, 0, 0, w, h, gl.RGBA, gl.UNSIGNED_BYTE, image.pixels.rgba32.ptr);
    gl.GenerateTextureMipmap(texture);

    // TODO: texture appears white for some reason

    return .{
        .handle = texture,
    };
}

pub fn deinit(self: *Texture, _: std.mem.Allocator) void {
    gl.DeleteTextures(1, @ptrCast(&self.handle));
}
