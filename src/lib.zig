const std = @import("std");
const builtin = @import("builtin");

pub const io = @import("assets/io.zig");
const obj_import = @import("assets/obj_import.zig");

const graphics = @import("graphics/graphics.zig");
pub const RenderMode = graphics.RenderMode;
pub const setRenderMode = graphics.setRenderMode;

pub const math = @import("math/math.zig");
pub const events = @import("events.zig");

pub const Event = events.Event;
pub const Window = @import("Window.zig");
pub const Input = @import("Input.zig");
pub const Time = @import("Time.zig");

pub const Model = obj_import.Model;
pub const MeshData = obj_import.MeshData;
pub const MeshInstance = @import("graphics/MeshInstance.zig");
pub const Material = @import("graphics/Material.zig");
pub const Image = @import("zigimg").Image;
pub const Texture = @import("graphics/Texture.zig");
pub const Shader = @import("graphics/Shader.zig");

const log = std.log.scoped(.engine);

window: Window,
input: Input,
time: Time,

const Engine = @This();

/// Call `deinit` at the end
pub fn init(options: Options) EngineError!Engine {
    const window = Window.create(options.window_width, options.window_height, options.title) catch |e| {
        log.err("Failed to create a window", .{});
        return e;
    };
    errdefer window.destroy();

    graphics.init() catch |err| {
        log.err("Failed to load a graphics library", .{});
        return err;
    };
    errdefer graphics.deinit();

    return .{
        .window = window,
        .input = .{ .pointer_position = .zero },
        .time = try .init(),
    };
}

pub fn deinit(self: *Engine) void {
    log.info("Shutting down...", .{});

    self.window.destroy();
    graphics.deinit();
}

/// Call this function when you are ready to start your application.
/// The `your_context` argument is for your own application data and will be passed to callbacks
/// as part of an `App` struct.
///
/// WARNING: This places the thread into an infinite update loop until the window closes.
/// You should do all necessary setup before calling this function.
pub fn run(self: *Engine, comptime T: type, user_data: *T, on_update: fn(*Engine, *T) EngineError!void, on_event: fn (*Engine, *T, Event) EngineError!void) !void {
    while (!self.window.should_close) {
        // Process pending OS events
        while (self.window.areEventsPending()) {
            if (self.window.consumeEvent(self.input)) |ev| {
                // Special handling for important events
                switch (ev) {
                    .window_close => {
                        self.window.should_close = true;
                    },
                    .window_resize => |r| {
                        graphics.adjustViewport(@intCast(r.width), @intCast(r.height));
                    },
                    .pointer_motion => |m| {
                        self.input.pointer_position = m.position;
                    },
                    else => {},
                }

                try on_event(self, user_data, ev);
            }
        }

        graphics.clear();

        self.time.update();

        // TODO: engine update loop
        try on_update(self, user_data);

        // NOTE: maybe introduce a `post_update`?

        self.window.swapBuffers();
    }
}

pub const Options = struct {
    title: []const u8,
    window_width: u32,
    window_height: u32,
};


pub const EngineError = error {
    InitFailure,
    IOError,
    OutOfMemory,
    ShaderCompilationFailure,
    InvalidData,
};

test {
    _ = std.testing.refAllDeclsRecursive(@This());
}
