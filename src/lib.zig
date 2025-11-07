const std = @import("std");
const builtin = @import("builtin");

pub const math = @import("math/math.zig");
pub const events = @import("events.zig");
pub const Event = events.Event;
pub const Input = @import("Input.zig");
const renderer = @import("rendering/renderer.zig");

pub const RenderMode = renderer.RenderMode;
pub const setRenderMode = renderer.setRenderMode;

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

    renderer.init() catch |err| {
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

    const values: [3]math.Vec3 = .{ .splat(0.2), .splat(-0.2), .splat(0.0) };
    test_shader.use();
    _=test_shader.setUniform("values", values);

    // TEMP
    const verts = [_]f32{
        // positions        // colors
        -0.5, -0.5, 0.0,    1.0, 1.0, 1.0,  // bottom left
         0.5, -0.5, 0.0,    1.0, 0.0, 0.0,  // bottom right
         0.5,  0.5, 0.0,    0.0, 1.0, 0.0,  // top right
        -0.5,  0.5, 0.0,    0.0, 0.0, 1.0,  // top left
    };
    const indices = [_]c_uint{
        0, 1, 3,
        1, 2, 3,
    };
    try asset_manager.loadMeshTemp("quad", &verts, &indices);
    const quad = asset_manager.getMesh("quad").?;

    const verts2 = [_]f32{
        -0.5, -0.5, 0.0,    1.0, 0.0, 0.0,
         0.5, -0.5, 0.0,    0.0, 1.0, 0.0,
         0.0,  0.5, 0.0,    0.0, 0.0, 1.0,
    };
    try asset_manager.loadMeshTemp("tri", &verts2, &.{0,1,2});
    const tri = asset_manager.getMesh("tri").?;

    log.info("Press left mouse to toggle shader, press right mouse to toggle mesh", .{});

    var cur_mesh: i32 = 0;
    var cur_shader: i32 = 0;
    var framecount: f32 = 0;
    // TEMP

    // Engine loop
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
                        renderer.adjustViewport(@intCast(window.width), @intCast(window.height));
                    },
                    .pointer_button_press => |e| {
                        if (e.button == 1) cur_shader ^= 1;
                        if (e.button == 3) cur_mesh ^= 1;
                    },
                    else => {},
                }

                on_event(ev);
            }
        }

        // TODO: engine update loop
        on_update();

        // TEMP
        const mesh = if (cur_mesh == 0) quad else tri;
        const shader = if (cur_shader == 0) default_shader else test_shader;

        renderer.render(mesh, shader);

        const timeSine = @sin(framecount / 60.0);
        framecount+=1;
        _=shader.setUniform("timeSine", timeSine);
        // TEMP


        window.swapBuffers();
    }


    log.info("Shutting down...", .{}); 
}

test {
    _ = std.testing.refAllDeclsRecursive(@This());
}
