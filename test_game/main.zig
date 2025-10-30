const std = @import("std");

const engine = @import("engine");

pub fn main() !void {
    std.debug.print("gaming\n", .{});
    // Setup game here
    const app: engine.App = .{
        .title = "Gaming",
        .on_update = undefined,
        .on_event = &on_event,
    };

    try engine.runApplication(app);
}

fn on_event(event: engine.Event) void {
    switch (event) {
        .key_press => |ev| {
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
        .pointer_motion => |ev| {
            std.debug.print("m({},{}) ", .{ev[0], ev[1]});
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
        .window_resize => |ev| {
            std.debug.print("resize {}, {} ", .{ev.width, ev.height});
        },
        .window_close => {
            std.debug.print("closed ", .{});
        },
    }
}
