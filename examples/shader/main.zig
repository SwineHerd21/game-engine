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
};
const App = engine.App(State);

fn on_init(app: *App) !void {
    var assets = app.asset_manager;

    const fancy_material = try assets.getOrLoad(engine.Material, "fancy.mat");
    // You can pass even arrays of VecN to shaders!
    const values: [3]engine.math.Vec3 = .{ .splat(0.2), .splat(-0.2), .splat(0.0) };
    fancy_material.use();
    _=fancy_material.setUniform("values", values);

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
    try assets.put("quad", engine.Mesh.init(&verts, &indices));

    const verts2 = [_]f32{
        -0.5, -0.5, 0.0,    1.0, 0.0, 0.0,
         0.5, -0.5, 0.0,    0.0, 1.0, 0.0,
         0.0,  0.5, 0.0,    0.0, 0.0, 1.0,
    };
    try assets.put("tri", engine.Mesh.init(&verts2, &.{0,1,2}));

    std.debug.print("\nPress any key to switch between solid and line rendering\n\n", .{});
}

fn on_update(app: *App) !void {
    const assets = app.asset_manager;

    const quad = assets.getNamed(engine.Mesh, "quad").?;
    // This asset has not been loaded yet so we should use 'assets.getOrLoad()'
    const default_mat = try assets.getOrLoad(engine.Material, "default.mat");
    quad.draw(default_mat);

    const tri = assets.getNamed(engine.Mesh, "tri").?;
    // This asset was already loaded in 'on_init()' so we can use 'assets.get()'
    const fancy_mat = assets.get(engine.Material, "fancy.mat").?;
    tri.draw(fancy_mat);

    // This is after 'draw' because uniforms are actually applied to the currently loaded shader,
    // not the one passed to the 'setUniform' method)
    const timeSine = @sin(app.time.totalRuntime);
    _=fancy_mat.setUniform("timeSine", timeSine);
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
