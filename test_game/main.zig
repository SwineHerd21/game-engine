const std = @import("std");

const engine = @import("engine");


pub fn main() !void {
    std.debug.print("gaming\n", .{});
    // Setup game here
    try engine.runApplication(undefined, &on_event, .{
        .title = "Gaming",
        .init_width = 800,
        .init_height = 600,
    });
}

var rendermode = engine.RenderMode.Solid;
fn on_event(event: engine.Event) void {
    switch (event) {
        .key_press => |ev| {
            // Switch between solid and wireframe rendering
            rendermode = @enumFromInt(@intFromEnum(rendermode) ^ 1);
            engine.setRenderMode(rendermode);
            std.debug.print("pressed {} (control:{}, shift:{}, alt:{}, super:{}) ", .{
                ev.keycode,
                ev.modifiers.control,
                ev.modifiers.shift,
                ev.modifiers.alt,
                ev.modifiers.super,
            });
        },
        .key_release => |ev| {
            std.debug.print("released {} (control:{}, shift:{}, alt:{}, super:{}) ", .{
                ev.keycode,
                ev.modifiers.control,
                ev.modifiers.shift,
                ev.modifiers.alt,
                ev.modifiers.super,
            });
        },
        .pointer_button_press => |ev| {
            std.debug.print("mouse pressed {} ", .{ev.button});
        },
        .pointer_button_release => |ev| {
            std.debug.print("mouse released {} ", .{ev.button});
        },
        .pointer_enter => {
            std.debug.print("entered ", .{});
        },
        .pointer_exit => {
            std.debug.print("exited ", .{});
        },
        .focus_gained => {
            std.debug.print("focus ", .{});
        },
        .focus_lost => {
            std.debug.print("unfocus ", .{});
        },
        else => {},
    }
}
