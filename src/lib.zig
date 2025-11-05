const std = @import("std");
const builtin = @import("builtin");

pub const events = @import("events.zig");
pub const Event = events.Event;
pub const Input = @import("Input.zig");

pub const RenderMode = @import("rendering/Renderer.zig").RenderMode;
pub const setRenderMode = @import("rendering/Renderer.zig").setRenderMode;

const Renderer = @import("rendering/Renderer.zig");
const Window = @import("Window.zig");
const AssetManager = @import("assets/AssetManager.zig");

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
    // Initialization
    var window = Window.createWindow(config.init_width, config.init_height, config.title) catch |e| {
        log.err("Failed to create a window", .{});
        return e;
    };
    defer window.destroy();

    var renderer = Renderer.init() catch |err| {
            log.err("Failed to load a graphics library", .{});
            return err;
    };
    defer renderer.deinit();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var asset_manager = AssetManager.init(allocator);
    defer asset_manager.deinit();

    try asset_manager.loadShader("default", "shaders/default.vert", "shaders/default.frag");
    const default_shader = asset_manager.getShader("default").?;

    try asset_manager.loadShader("test", "shaders/shader.vert", "shaders/shader.frag");
    const test_shader = asset_manager.getShader("test").?;

    const values: [3]f32 = .{0.2, -0.2, 0.0};
    test_shader.use();
    _=test_shader.setUniform(@TypeOf(values), .{.name = "values", .value = values});

    var cur_shader: i32 = 0;

    // Engine loop
    var framecount: f32 = 0;
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
                    .pointer_button_press => {
                        cur_shader ^= 1;
                    },
                    else => {},
                }

                on_event(ev);
            }
        }

        // TODO: engine update loop
        on_update();

        // temp for testing
        const shader = if (cur_shader == 0) default_shader else test_shader;
        shader.use();
        const timeSine = @sin(framecount / 60.0);
        framecount+=1;
        _=shader.setUniform(f32, .{.name = "timeSine", .value = timeSine});

        renderer.render();

        window.swapBuffers();
    }


    log.info("Shutting down...", .{}); 
}

test {
    _ = std.testing.refAllDeclsRecursive(@This());
}
