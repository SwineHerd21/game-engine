const std = @import("std");

const Window = @import("Window.zig");
const events = @import("events.zig");

const App = @This();

title: []const u8,
on_update: *const fn() void,
on_event: *const fn(event: events.Event) void,

pub fn run(self: App) !void {
    var window = try Window.createWindow(800, 600, self.title);
    defer window.destroy();

    // Do setup here

    while (!window.should_close) {
        if (window.consumeEvent()) |ev| {
            switch (ev) {
                .window_resize => |e| {
                    window.width = e.width;
                    window.height = e.height;
                },
                .window_close => {
                    window.should_close = true;
                },
                else => {},
            }

            self.on_event(ev);
        }
    }

    std.log.info("Shutting down...", .{}); 
}
