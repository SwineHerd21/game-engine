const std = @import("std");
const gl = @import("gl");

const Window = @import("Window.zig");
const Renderer = @import("rendering/Renderer.zig");

pub const events = @import("events.zig");
pub const Event = events.Event;


pub const AppConfiguration = struct {
    title: []const u8,
    init_width: u32,
    init_height: u32,
};

/// Call this function when you are ready to start your application.
///
/// WARNING: This places the thread into an infinite update loop until the window closes.
pub fn runApplication(on_update: *const fn() void, on_event: *const fn(event: events.Event) void, config: AppConfiguration) !void {
    var window = try Window.createWindow(config.init_width, config.init_height, config.title);
    defer window.destroy();

    var renderer = Renderer.init();
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
                    gl.Viewport(0, 0, @intCast(window.width), @intCast(window.height));

                    renderer.render(window);
                },
                else => {},
            }

            on_event(ev);
        }

        // TODO: update/render loop
    }

    _ = on_update;

    std.log.info("Shutting down...", .{}); 
}
