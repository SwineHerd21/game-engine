const std = @import("std");
const builtin = @import("builtin");

pub const events = @import("events.zig");
pub const Event = events.Event;
pub const Input = @import("Input.zig");

const Renderer = @import("rendering/Renderer.zig");
const Window = @import("Window.zig");

const log = std.log.scoped(.engine);

pub const EngineError = error {
    InitFailure,
};

pub const AppConfig = struct {
    title: []const u8,
    init_width: u32,
    init_height: u32,
};

/// Call this function when you are ready to start your application.
///
/// WARNING: This places the thread into an infinite update loop until the window closes.
/// This function will not pass on error and will close on fatal ones (like failing to open a window).
/// You should do all necessary cleanup before calling this function.
pub fn runApplication(on_update: *const fn() void, on_event: *const fn(event: events.Event) void, config: AppConfig) EngineError!void {
    var window = Window.createWindow(config.init_width, config.init_height, config.title) catch |e| {
        log.err("Failed to create a window", .{});
        return e;
    };
    defer window.destroy();

    var renderer = Renderer.init() catch |e| {
        log.err("Failed to load a graphics library", .{});
        return e;
    };

    defer renderer.deinit();
    renderer.createVertexBuffer();

    while (!window.should_close) {
        if (window.consumeEvent()) |ev| {
            // Special handling for important events
            switch (ev) {
                .window_resize => |e| {
                    window.width = e.width;
                    window.height = e.height;
                },
                .window_close => {
                    window.should_close = true;
                },
                .window_expose => {
                    Renderer.adjustViewport(@intCast(window.width), @intCast(window.height));

                    renderer.render(window);
                },
                else => {},
            }

            on_event(ev);
        }

        // TODO: update/render loop
    }

    _ = on_update;

    log.info("Shutting down...", .{}); 
}
