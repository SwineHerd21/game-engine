const std = @import("std");

const Window = @import("Window.zig");
pub const events = @import("events.zig");
pub const Event = events.Event;

pub const Platform = enum {
    X11,
    Windows,
};

pub const platform: Platform = switch (@import("builtin").os.tag) {
    .linux => .X11,
    .windows => .Windows,
    else => |os| @compileError(std.fmt.comptimePrint("Platform {} is not supported", .{@tagName(os)})),
};

/// Call this function when you are ready to start your application.
///
/// WARNING: This places the thread into an infinite update loop until the window closes.
pub fn runApplication(title: []const u8, on_update: *const fn() void, on_event: *const fn(event: events.Event) void) !void {
    var window = try Window.createWindow(800, 600, title);
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
                .window_expose => {
                    // TODO: opengl
                },
                else => {},
            }

            on_event(ev);
        }
    }

    _ = on_update;

    std.log.info("Shutting down...", .{}); 
}
