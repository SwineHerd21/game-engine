const std = @import("std");

const engine = @import("engine");


pub fn main() !void {
    std.debug.print("gaming\n", .{});
    // Setup game here
    try engine.runApplication(&on_update, &on_event, .{
        .title = "Gaming",
        .init_width = 800,
        .init_height = 600,
    });
}

fn on_update() void {
    // stub
}

var rendermode = engine.RenderMode.Solid;
fn on_event(event: engine.Event) void {
    switch (event) {
        .key_press => {
            // Switch between solid and wireframe rendering
            rendermode = @enumFromInt(@intFromEnum(rendermode) ^ 1);
            engine.setRenderMode(rendermode);
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
