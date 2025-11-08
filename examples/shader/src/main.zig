//! Demonstrates basic mesh/shader loading and rendering
//!
//! Press any keyboard button to switch between solid and line rendering

const std = @import("std");

const engine = @import("engine");

pub fn main() !void {
    std.debug.print("gaming\n", .{});

    const config: engine.Options(State) = .{
        .title = "Gaming",
        .window_width = 800,
        .window_height = 600,
        .asset_folder = "examples/shader/assets/",
        .on_init = on_init,
        .on_update = on_update,
        .on_event = on_event,
        .on_deinit = on_deinit,
    };
    var state: State = .{ .rendermode = .Solid };

    try engine.runApplication(State, &state, config);
}

const State = struct {
    rendermode: engine.RenderMode,
    framecount: f32 = 0,
};
const App = engine.App(State);

fn on_init(app: *App) !void {
    var assets = app.asset_manager;

    try assets.loadShader("default", "default.vert", "default.frag");

    try assets.loadShader("fancy", "fancy.vert", "fancy.frag");
    const fancy_shader = assets.getShader("fancy").?;

    // You can pass even arrays of VecN to shaders!
    const values: [3]engine.math.Vec3 = .{ .splat(0.2), .splat(-0.2), .splat(0.0) };
    fancy_shader.use();
    _=fancy_shader.setUniform("values", values);

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
    try assets.loadMeshTemp("quad", &verts, &indices);

    const verts2 = [_]f32{
        -0.5, -0.5, 0.0,    1.0, 0.0, 0.0,
         0.5, -0.5, 0.0,    0.0, 1.0, 0.0,
         0.0,  0.5, 0.0,    0.0, 0.0, 1.0,
    };
    try assets.loadMeshTemp("tri", &verts2, &.{0,1,2});

    std.debug.print("\nPress any key to switch between solid and line rendering\n\n", .{});
}

fn on_update(app: *App) !void {
    const assets = app.asset_manager;

    const quad = assets.getMesh("quad").?;
    const default_s = assets.getShader("default").?;
    quad.draw(default_s);

    const tri = assets.getMesh("tri").?;
    const fancy_s = assets.getShader("fancy").?;
    tri.draw(fancy_s);

    // This is after 'draw' because uniforms are actually applied to the currently loaded shader,
    // not the one passed to the 'setUniform' method)
    app.state.framecount+=1;
    const timeSine = @sin(app.state.framecount / 60.0);
    _=fancy_s.setUniform("timeSine", timeSine);
}

fn on_event(app: *App, event: engine.Event) !void {
    switch (event) {
        .key_press => {
            // Switch between solid and wireframe rendering
            app.state.rendermode = @enumFromInt(@intFromEnum(app.state.rendermode) ^ 1);
            engine.setRenderMode(app.state.rendermode);
        },
        else => {},
    }
}

fn on_deinit(_: *App) !void {}
