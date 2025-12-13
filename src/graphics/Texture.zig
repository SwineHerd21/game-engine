const std = @import("std");
const gl = @import("gl");
const zigimg = @import("zigimg");

const EngineError = @import("../lib.zig").EngineError;

const log = std.log.scoped(.engine);

const Texture = @This();

handle: gl.uint,

pub const Parameters = struct {
    wrap_x: WrapMode = .repeat,
    wrap_y: WrapMode = .repeat,
    min_filter: MinFilterMode = .nearest_mipmap_linear,
    mag_filter: MagFilterMode = .linear,
    generate_mipmaps: bool = true,
};

/// `data` can be freed immediately after texture creation
pub fn init(data: []const u8, width: usize, height: usize, format: PixelFormat, parameters: Parameters) EngineError!Texture {
    var texture: gl.uint = undefined;
    gl.CreateTextures(gl.TEXTURE_2D, 1, @ptrCast(&texture));

    gl.TextureParameteri(texture, gl.TEXTURE_WRAP_S, wrapToGl(parameters.wrap_x));
    gl.TextureParameteri(texture, gl.TEXTURE_WRAP_T, wrapToGl(parameters.wrap_y));
    gl.TextureParameteri(texture, gl.TEXTURE_MIN_FILTER, minFilterToGl(parameters.min_filter));
    gl.TextureParameteri(texture, gl.TEXTURE_MAG_FILTER, magFilterToGl(parameters.mag_filter));

    const w: gl.sizei = @intCast(width);
    const h: gl.sizei = @intCast(height);
    const gl_format = pixelFormatToGl(format);
    gl.TextureStorage2D(texture, 1, gl_format.internal, w, h);
    gl.TextureSubImage2D(texture, 0, 0, 0, w, h, gl_format.base, gl_format.data_type, data.ptr);
    if (parameters.generate_mipmaps) gl.GenerateTextureMipmap(texture);

    return .{
        .handle = texture,
    };
}

pub fn deinit(self: Texture) void {
    gl.DeleteTextures(1, @ptrCast(&self.handle));
}

/// Determines how texture coordinates outside [0, 1] will be handled when using this texture in shaders
pub const WrapMode = enum {
    /// Texture coordinates outside [0, 1] will be clamped
    clamp,
    /// Texture coordinates outside [0, 1] will wrap for one mirrored reptition of the texture, after that the same as `clamp`
    mirror_and_clamp,
    /// Texture coordinates outside [0, 1] will wrap around
    repeat,
    /// Texture coordinates outside [0, 1] will wrap around and mirror the texture
    repeat_mirrored,
};

/// Determines how color values are sampled when the texture is downscaled
pub const MinFilterMode = enum {
    nearest,
    linear,
    /// Chooses the nearest mipmap, then the same as `nearest`
    nearest_mipmap_nearest,
    /// Chooses the nearest mipmap, then the same as `linear`
    linear_mipmap_nearest,
    /// Interpolated between two closest mipmaps, then the same as `nearest`
    nearest_mipmap_linear,
    /// Interpolated between two closest mipmaps, then the same as `linear`
    linear_mipmap_linear,
};

/// Determines how color values are sampled when the texture is upscaled
pub const MagFilterMode = enum {
    /// Chooses the nearest texel
    nearest,
    /// Linearly interpolates between the closest texels
    linear,
};

/// For the r8/rg16/rgba32/etc. type formats the letters indicate channels, the numbers indicate
/// how many bits each channel uses, `f` means the values are floats
pub const PixelFormat = enum {
    r8,
    r16,
    r32f,
    rg8,
    rg16,
    rg32f,
    rgb8,
    rgb16,
    rgb32f,
    /// 3 bits each RG and 2 bits for B
    rgb332,
    /// 5 bits for each RB and 6 bits for G
    rgb565,
    rgba4,
    rgba8,
    rgba16,
    rgba32f,
    /// 5 bits for each RGB and 1 bit for alpha
    rgb5a1,
    /// 10 bits for each RGB and 2 bits for alpha
    rgb10a2,
    /// 16 bit integers mapped to [0, 1] depth values
    depth16,
    /// 32 bit integers mapped to [0, 1] depth values
    depth24,
    /// f32 depth values
    depth32f,
    /// 24 bits for depth value and 8 bits for stencil value
    depth24_stencil8,
    /// f32 for depth value and 8 bits for stencil value
    depth32f_stencil8,
    /// 8 bit stencil values
    stencil8,
};


// TODO: eventually make the renderer abstraction have these functions
fn wrapToGl(mode: WrapMode) gl.int {
    return switch (mode) {
        .clamp => gl.CLAMP_TO_EDGE,
        .mirror_and_clamp => gl.MIRROR_CLAMP_TO_EDGE,
        .repeat => gl.REPEAT,
        .repeat_mirrored => gl.MIRRORED_REPEAT,
    };
}

fn magFilterToGl(mode: MagFilterMode) gl.int {
    return switch (mode) {
        .nearest => gl.NEAREST,
        .linear => gl.LINEAR,
    };
}

fn minFilterToGl(mode: MinFilterMode) gl.int {
    return switch (mode) {
        .nearest => gl.NEAREST,
        .linear => gl.LINEAR,
        .nearest_mipmap_nearest => gl.NEAREST_MIPMAP_NEAREST,
        .linear_mipmap_nearest => gl.LINEAR_MIPMAP_NEAREST,
        .nearest_mipmap_linear => gl.NEAREST_MIPMAP_LINEAR,
        .linear_mipmap_linear => gl.LINEAR_MIPMAP_LINEAR,
    };
}

const GlPixelFormatData = struct {
    base: gl.@"enum",
    internal: gl.@"enum",
    data_type: gl.@"enum",
};

fn pixelFormatToGl(format: PixelFormat) GlPixelFormatData {
    const base: gl.@"enum" = switch (format) {
        .r8, .r16, .r32f => gl.RED,
        .rg8, .rg16, .rg32f => gl.RG,
        .rgb8, .rgb16, .rgb32f, .rgb332, .rgb565 => gl.RGB,
        .rgba4, .rgba8, .rgba16, .rgba32f, .rgb5a1, .rgb10a2 => gl.RGBA,
        .depth16, .depth24, .depth32f => gl.DEPTH_COMPONENT,
        .depth24_stencil8, .depth32f_stencil8 => gl.DEPTH_STENCIL,
        .stencil8 => gl.STENCIL_INDEX,
    };
    const internal: gl.@"enum" = switch (format) {
        .r8 => gl.R8,
        .r16 => gl.R16,
        .r32f => gl.R32F,
        .rg8 => gl.RG8,
        .rg16 => gl.RG16,
        .rg32f => gl.RG32F,
        .rgb8 => gl.RGB8,
        .rgb16 => gl.RGB16,
        .rgb32f => gl.RGB32F,
        .rgb332 => gl.R3_G3_B2,
        .rgb565 => gl.RGB565,
        .rgba4 => gl.RGBA4,
        .rgba8 => gl.RGBA8,
        .rgba16 => gl.RGBA16,
        .rgba32f => gl.RGBA32F,
        .rgb5a1 => gl.RGB5_A1,
        .rgb10a2 => gl.RGB10_A2,
        .depth16 => gl.DEPTH_COMPONENT16,
        .depth24 => gl.DEPTH_COMPONENT24,
        .depth32f => gl.DEPTH_COMPONENT32F,
        .depth24_stencil8 => gl.DEPTH24_STENCIL8,
        .depth32f_stencil8 => gl.DEPTH32F_STENCIL8,
        .stencil8 => gl.STENCIL_INDEX8,
    };

    const data_type: gl.@"enum" = switch (format) {
        .r8, .rg8, .rgb8, .rgba8, .stencil8 => gl.UNSIGNED_BYTE,
        .r16, .rg16, .rgb16, .rgba16, .depth16 => gl.UNSIGNED_SHORT,
        .r32f, .rg32f, .rgb32f, .rgba32f, .depth32f => gl.FLOAT,
        .depth24 => gl.UNSIGNED_INT,
        .rgb332 => gl.UNSIGNED_BYTE_3_3_2,
        .rgb565 => gl.UNSIGNED_SHORT_5_6_5,
        .rgba4 => gl.UNSIGNED_SHORT_4_4_4_4,
        .rgb5a1 => gl.UNSIGNED_SHORT_5_5_5_1,
        .rgb10a2 => gl.UNSIGNED_INT_10_10_10_2,
        .depth24_stencil8 => gl.UNSIGNED_INT_24_8,
        .depth32f_stencil8 => gl.FLOAT_32_UNSIGNED_INT_24_8_REV,
    };

    return .{
        .base = base,
        .internal = internal,
        .data_type = data_type,
    };
}
