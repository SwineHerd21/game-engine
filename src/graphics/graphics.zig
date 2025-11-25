//! OpenGL renderer

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

    gl.Enable(gl.DEPTH_TEST);
    // Default winding order is CCW
    // gl.Enable(gl.CULL_FACE);
}

pub fn deinit() void {
    gl.makeProcTableCurrent(null);
}

// ========== Utilities ==========

pub fn adjustViewport(width: i32, height: i32) void {
    gl.Viewport(0, 0, width, height);
}

pub fn setRenderMode(mode: RenderMode) void {
    gl.PolygonMode(gl.FRONT_AND_BACK, switch (mode) {
        .Solid => gl.FILL,
        .Wireframe => gl.LINE,
    });
}

// ========== Render ==========

pub fn clear() void {
    gl.ClearColor(0.0, 0.0, 0.0, 1.0);
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
}
