const std = @import("std");
const math = @import("../math/math.zig");

pub const Rgba = packed struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,

    pub const empty: Rgba = new(0, 0, 0, 0);
    pub const black: Rgba = new(0, 0, 0, 255);
    pub const gray: Rgba = new(127, 127, 127, 255);
    pub const white: Rgba = new(255, 255, 255, 255);
    pub const red: Rgba = new(255, 0, 0, 255);
    pub const green: Rgba = new(0, 255, 0, 255);
    pub const blue: Rgba = new(0, 0, 255, 255);
    pub const yellow: Rgba = new(255, 255, 0, 255);
    pub const cyan: Rgba = new(0, 255, 255, 255);
    pub const magenta: Rgba = new(255, 0, 255, 255);

    pub fn new(r: u8, g: u8, b: u8, a: u8) Rgba {
        return .{
            .r = r,
            .g = g,
            .b = b,
            .a = a,
        };
    }

    pub fn fromRGB(rgb: Rgb, alpha: u8) Rgba {
        return .{
            .r = rgb.r,
            .g = rgb.g,
            .b = rgb.b,
            .a = alpha,
        };
    }

    pub fn newOpaque(r: u8, g: u8, b: u8) Rgba {
        return .{
            .r = r,
            .g = g,
            .b = b,
            .a = 255,
        };
    }

    /// Cast to a `Vec4f` with each component in range [0, 1]
    pub fn toVec4f(c: Rgba) math.Vec4f {
        return .{
            .x = @as(f32, @floatFromInt(c.r)) / 255.0,
            .y = @as(f32, @floatFromInt(c.g)) / 255.0,
            .z = @as(f32, @floatFromInt(c.b)) / 255.0,
            .w = @as(f32, @floatFromInt(c.a)) / 255.0,
        };
    }
    /// Cast from a `Vec4f`, clamping each component in range [0, 1]
    pub fn fromVec4f(v: math.Vec4f) Rgba {
        return .{
            .r = @intFromFloat(std.math.clamp(v.x, 0, 1) * 255.0),
            .g = @intFromFloat(std.math.clamp(v.y, 0, 1) * 255.0),
            .b = @intFromFloat(std.math.clamp(v.z, 0, 1) * 255.0),
            .a = @intFromFloat(std.math.clamp(v.w, 0, 1) * 255.0),
        };
    }

    pub fn format(
        self: @This(),
        writer: *std.Io.Writer,
    ) std.Io.Writer.Error!void {
        try writer.print("#{X}{X}{X}{X}", self);
    }
};

pub const Rgb = packed struct {
    r: u8,
    g: u8,
    b: u8,

    pub const black: Rgb = new(0, 0, 0);
    pub const gray: Rgb = new(127, 127, 127);
    pub const white: Rgb = new(255, 255, 255);
    pub const red: Rgb = new(255, 0, 0);
    pub const green: Rgb = new(0, 255, 0);
    pub const blue: Rgb = new(0, 0, 255);
    pub const yellow: Rgb = new(255, 255, 0);
    pub const cyan: Rgb = new(0, 255, 255);
    pub const magenta: Rgb = new(255, 0, 255);

    pub fn new(r: u8, g: u8, b: u8) Rgb {
        return .{
            .r = r,
            .g = g,
            .b = b,
        };
    }

    /// Cast to a `Vec4f` with each component in range [0, 1]
    pub fn toVec4f(c: Rgb) math.Vec4f {
        return .{
            .x = @as(f32, @floatFromInt(c.r)) / 255.0,
            .y = @as(f32, @floatFromInt(c.g)) / 255.0,
            .z = @as(f32, @floatFromInt(c.b)) / 255.0,
        };
    }
    /// Cast from a `Vec4f`, clamping each component in range [0, 1]
    pub fn fromVec4f(v: math.Vec4f) Rgb {
        return .{
            .r = @intFromFloat(std.math.clamp(v.x, 0, 1) * 255.0),
            .g = @intFromFloat(std.math.clamp(v.y, 0, 1) * 255.0),
            .b = @intFromFloat(std.math.clamp(v.z, 0, 1) * 255.0),
        };
    }

    pub fn format(
        self: @This(),
        writer: *std.Io.Writer,
    ) std.Io.Writer.Error!void {
        try writer.print("#{X}{X}{X}", self);
    }
};
