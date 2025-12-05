//! OpenGL renderer

const builtin = @import("builtin");
const std = @import("std");
const gl = @import("gl");

const native = @import("../platform.zig").native;

const Window = @import("../Window.zig");
const EngineError = @import("../lib.zig").EngineError;

const log = std.log.scoped(.opengl);

pub const RenderMode = enum {
    Solid,
    Wireframe,
};

// OpenGL runtime loaded functions
var procs: gl.ProcTable = undefined;

/// Call `deinit()` at the end
pub fn init() EngineError!void {
    // Load OpenGL functions
    if (!procs.init(native.getProcAddress)) return EngineError.InitFailure;
    gl.makeProcTableCurrent(&procs);

    const gl_version: [*:0]const u8 = gl.GetString(gl.VERSION).?;
    log.info("Rendering with OpenGL {s}", .{ gl_version });

    gl.Enable(gl.DEBUG_OUTPUT);
    gl.Enable(gl.DEBUG_OUTPUT_SYNCHRONOUS);
    gl.DebugMessageCallback(messageCallback, null);

    if (builtin.mode != .Debug) {
        gl.DebugMessageControl(gl.DONT_CARE, gl.DEBUG_TYPE_ERROR | gl.DEBUG_TYPE_PERFORMANCE, gl.DEBUG_SEVERITY_HIGH | gl.DEBUG_SEVERITY_MEDIUM, 0, null, gl.TRUE);
    }

    gl.Enable(gl.DEPTH_TEST);
    // Default winding order is CCW
    gl.Enable(gl.CULL_FACE);
}

pub fn deinit() void {
    gl.makeProcTableCurrent(null);
}

// ========== Utilities ==========

pub fn adjustViewport(width: i32, height: i32) void {
    gl.Viewport(0, 0, width, height);
}

pub fn setRenderMode(mode: RenderMode) void {
    switch (mode) {
        .Solid => {
            gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL);
            gl.Enable(gl.CULL_FACE);
        },
        .Wireframe => {
            gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE);
            gl.Disable(gl.CULL_FACE);
        },
    }
}

fn messageCallback(source: gl.@"enum", msg_type: gl.@"enum", id: gl.uint, severity: gl.@"enum", length: gl.sizei, message: [*]const u8, _: ?*const anyopaque) callconv(.c) void {
    const src = switch (source) {
        gl.DEBUG_SOURCE_API => "API",
        gl.DEBUG_SOURCE_WINDOW_SYSTEM => "Window system",
        gl.DEBUG_SOURCE_SHADER_COMPILER => "Shader compiler",
        gl.DEBUG_SOURCE_THIRD_PARTY => "Third party",
        gl.DEBUG_SOURCE_APPLICATION => "Application",
        gl.DEBUG_SOURCE_OTHER => "Other",
        else => unreachable,
    };
    const t = switch (msg_type) {
        gl.DEBUG_TYPE_ERROR => "ERROR",
        gl.DEBUG_TYPE_DEPRECATED_BEHAVIOR => "Deprecated behaviour",
        gl.DEBUG_TYPE_UNDEFINED_BEHAVIOR => "Undefined behaviour",
        gl.DEBUG_TYPE_PORTABILITY => "Portability",
        gl.DEBUG_TYPE_PERFORMANCE => "Performance",
        gl.DEBUG_TYPE_MARKER => "Marker",
        gl.DEBUG_TYPE_PUSH_GROUP => "Push group",
        gl.DEBUG_TYPE_POP_GROUP => "Pop group",
        gl.DEBUG_TYPE_OTHER => "Other",
        else => unreachable,
    };

    const fmt = "{s}|{s} {}: {s}";
    const args = .{src, t, id, message[0..@as(usize, @intCast(length))]};
    switch (severity) {
        gl.DEBUG_SEVERITY_HIGH => {log.err(fmt, args);std.process.exit(1);},
        gl.DEBUG_SEVERITY_MEDIUM => log.warn(fmt, args),
        gl.DEBUG_SEVERITY_LOW => log.debug(fmt, args),
        gl.DEBUG_SEVERITY_NOTIFICATION => log.info(fmt, args),
        else => unreachable,
    }
}

// ========== Render ==========

pub fn clear() void {
    gl.ClearColor(0.0, 0.0, 0.0, 1.0);
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
}

