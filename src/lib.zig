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
pub const Texture = @import("graphics/Texture.zig");
pub const shaders = @import("graphics/shaders.zig");

const log = std.log.scoped(.engine);

pub const EngineError = error {
    InitFailure,
    IOError,
    OutOfMemory,
    ShaderCompilationFailure,
    InvalidAssetType,
    AssetLoadError,
};

pub fn Options(comptime T: type) type {
    return struct {
        title: []const u8,
        window_width: u32,
        window_height: u32,

        asset_folder: []const u8,

        /// Gets called once every frame
        on_update: *const fn(*App(T)) EngineError!void,
        /// Gets called when a window event is handled
        on_event: *const fn(*App(T), events.Event) EngineError!void,
    };
}

/// A wrapper that couples your own application state with the engine.
pub fn App(comptime T: type) type {
    return struct {
        state: *T,
        window: Window,
        assets: AssetManager,
        input: Input,
        time: Time,

        /// Gets called once every frame
        on_update: *const fn(*App(T)) EngineError!void,
        /// Gets called when a window event is handled
        on_event: *const fn(*App(T), events.Event) EngineError!void,

        const Self = @This();

        /// Call `deinit` at the end
        pub fn init(your_context: *T, allocator: std.mem.Allocator, options: Options(T)) EngineError!Self {
            var asset_manager = AssetManager.init(allocator, options.asset_folder);
            errdefer asset_manager.deinit();

            try asset_manager.registerAssetType(shaders.Vertex, shaders.Vertex.init, shaders.Vertex.deinit);
            try asset_manager.registerAssetType(shaders.Fragment, shaders.Fragment.init, shaders.Fragment.deinit);
            try asset_manager.registerAssetType(Texture, Texture.init, Texture.deinit);
            try asset_manager.registerAssetType(Material, Material.init, Material.deinit);
            try asset_manager.registerAssetType(Mesh, init_2, Mesh.deinit);

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
                .state = your_context,
                .window = window,
                .assets = asset_manager,
                .input = .{ .pointer_position = .zero },
                .time = try .init(),
                .on_update = options.on_update,
                .on_event = options.on_event,
            };
        }

        pub fn deinit(self: *Self) void {
            log.info("Shutting down...", .{});

            self.assets.deinit();
            self.window.destroy();
            graphics.deinit();
        }

        /// Call this function when you are ready to start your application.
        /// The `your_context` argument is for your own application data and will be passed to callbacks
        /// as part of an `App` struct.
        ///
        /// WARNING: This places the thread into an infinite update loop until the window closes.
        /// You should do all necessary setup before calling this function.
        pub fn run(self: *Self) !void {
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

                        try self.on_event(self, ev);
                    }
                }

                graphics.clear();

                self.time.update();

                // TODO: engine update loop
                try self.on_update(self);

                // NOTE: maybe introduce a `post_update`?

                self.window.swapBuffers();
            }
        }
    };
}

fn init_2(_:[]const u8, _:*AssetManager) !Mesh {
    return undefined;
}

test {
    _ = std.testing.refAllDeclsRecursive(@This());
}
