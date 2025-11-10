const std = @import("std");
const builtin = @import("builtin");

const graphics = @import("graphics/graphics.zig");

pub const math = @import("math/math.zig");
pub const events = @import("events.zig");
pub const Input = @import("Input.zig");

pub const Window = @import("Window.zig");
pub const Event = events.Event;

pub const RenderMode = graphics.RenderMode;
pub const setRenderMode = graphics.setRenderMode;

pub const AssetManager = @import("assets/AssetManager.zig");
pub const Time = @import("Time.zig");

pub const Mesh = @import("graphics/Mesh.zig");
pub const Material = @import("graphics/Material.zig");
pub const shaders = @import("graphics/shaders.zig");

const log = std.log.scoped(.engine);

pub const EngineError = error {
    InitFailure,
    ShaderCompilationFailure,
    IOError,
    OutOfMemory,
    InvalidAssetType,
    AssetLoadError,
};

pub fn Options(comptime T: type) type {
    return struct {
        title: []const u8,
        window_width: u32,
        window_height: u32,

        asset_folder: []const u8,

        /// Gets called when the application is initialized
        on_init: *const fn(*App(T)) EngineError!void,
        /// Gets called once every frame
        on_update: *const fn(*App(T)) EngineError!void,
        /// Gets called when a window event is handled
        on_event: *const fn(*App(T), events.Event) EngineError!void,
        /// Gets called before the application closes
        on_deinit: *const fn(*App(T)) EngineError!void,
    };
}

/// A wrapper that couples your own application state with the engine.
pub fn App(comptime T: type) type {
    return struct {
        state: *T,
        asset_manager: *AssetManager,
        time: Time,
    };
}

fn init_2(_:[]const u8, _:*AssetManager) !Mesh {
    return undefined;
}
/// Call this function when you are ready to start your application.
/// The 'your_context' argument is for your own application data and will be passed to callbacks
/// as part of an 'App' struct.
///
/// WARNING: This places the thread into an infinite update loop until the window closes.
/// This function will not pass on error and will close on fatal ones (like failing to open a window).
/// You should do all necessary cleanup before calling this function.
pub fn runApplication(comptime T: type, your_context: *T, options: Options(T)) EngineError!void {
    // Initialization
    var window = Window.createWindow(options.window_width, options.window_height, options.title) catch |e| {
        log.err("Failed to create a window", .{});
        return e;
    };
    defer window.destroy();

    graphics.init() catch |err| {
        log.err("Failed to load a graphics library", .{});
        return err;
    };
    defer graphics.deinit();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var asset_manager = AssetManager.init(allocator, options.asset_folder);
    defer asset_manager.deinit();

    try asset_manager.registerAssetType(shaders.Vertex, shaders.Vertex.init, shaders.Vertex.deinit);
    try asset_manager.registerAssetType(shaders.Fragment, shaders.Fragment.init, shaders.Fragment.deinit);
    try asset_manager.registerAssetType(Material, Material.init, Material.deinit);
    try asset_manager.registerAssetType(Mesh, init_2, Mesh.deinit);

    var app: App(T) = .{
        .state = your_context,
        .asset_manager = &asset_manager,
        .time = try .init(),
    };

    try options.on_init(&app);

    // Update loop
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
                        graphics.adjustViewport(@intCast(window.width), @intCast(window.height));
                    },
                    else => {},
                }

                try options.on_event(&app, ev);
            }
        }

        graphics.clear();

        app.time.update();

        // TODO: engine update loop
        try options.on_update(&app);

        window.swapBuffers();
    }

    log.info("Shutting down...", .{});
    try options.on_deinit(&app);
}

test {
    _ = std.testing.refAllDeclsRecursive(@This());
}
