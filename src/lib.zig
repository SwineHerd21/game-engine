const std = @import("std");
const builtin = @import("builtin");

pub const events = @import("events.zig");
pub const Event = events.Event;
pub const Input = @import("Input.zig");
pub const RenderMode = @import("rendering/Renderer.zig").RenderMode;
pub const setRenderMode = @import("rendering/Renderer.zig").setRenderMode;

const Renderer = @import("rendering/Renderer.zig");
const Window = @import("Window.zig");

const log = std.log.scoped(.engine);

pub const EngineError = error {
    InitFailure,
    ShaderCompilationFailure,
    IOError,
    OutOfMemory,
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

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var renderer = Renderer.init(allocator) catch |err| switch (err) {
        EngineError.InitFailure => {
            log.err("Failed to load a graphics library", .{});
            return err;
        },
        else => {
            log.err("Could not compile shaders", .{});
            return err;
        },
    };
    defer renderer.deinit();

    while (!window.should_close) {
        // Process pending OS events
        while (window.areEventsPending()) {
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
                    },
                    else => {},
                }

                on_event(ev);
            }
        }

        // TODO: engine update loop
        on_update();

        renderer.render();

        window.swapBuffers();
    }


    log.info("Shutting down...", .{}); 
}

test {
    _ = std.testing.refAllDeclsRecursive(@This());
}
