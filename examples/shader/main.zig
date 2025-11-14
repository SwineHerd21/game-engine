//! Demonstrates basic mesh/shader loading and rendering
//!
//! Press F1 to switch between solid and line rendering

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
    var state: State = undefined;
    state.rendermode = .Solid;

    try engine.runApplication(State, &state, config);
}

const State = struct {
    quad: engine.Mesh,
    fancy_mat: engine.Material,
    tri: engine.Mesh,
    default_mat: engine.Material,
    rendermode: engine.RenderMode,
};
const App = engine.App(State);

fn on_init(app: *App) !void {
    var assets = app.asset_manager;

    app.state.default_mat = try assets.getOrLoad(engine.Material, "default.mat");
    app.state.fancy_mat = try assets.getOrLoad(engine.Material, "fancy.mat");
    // You can pass even arrays of VecN to shaders!
    const values: [3]engine.math.Vec3 = .{ .splat(0.2), .splat(-0.2), .splat(0.0) };
    app.state.fancy_mat.setUniform("values", values);

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
    app.state.quad = assets.getNamed(engine.Mesh, "quad").?;

    const verts2 = [_]f32{
        -0.5, -0.5, 0.0,    1.0, 0.0, 0.0,
         0.5, -0.5, 0.0,    0.0, 1.0, 0.0,
         0.0,  0.5, 0.0,    0.0, 0.0, 1.0,
    };
    try assets.put("tri", engine.Mesh.init(&verts2, &.{0,1,2}));
    app.state.tri = assets.getNamed(engine.Mesh, "tri").?;

    std.debug.print("\nPress F1 to switch between solid and line rendering\n\n", .{});
}

var avrg_fps: f32 = 0;
var frames: f32 = 0;
fn on_update(app: *App) !void {
    const timeSine = @sin(app.time.totalRuntime);
    app.state.fancy_mat.setUniform("timeSine", timeSine);

    app.state.quad.draw(app.state.default_mat);
    app.state.tri.draw(app.state.fancy_mat);


    const cur_fps = 1/app.time.deltaTime;
    avrg_fps = (frames*avrg_fps + cur_fps) / (frames + 1);
    frames += 1;
    std.debug.print("\rAverage FPS: {}; Current FPS: {}", .{avrg_fps,cur_fps});
}

fn on_event(app: *App, event: engine.Event) !void {
    switch (event) {
        .key_press => |ev| {
            if (ev.key != .F1 or ev.action == .Repeat) return;
            // Switch between solid and wireframe rendering
            app.state.rendermode = @enumFromInt(@intFromEnum(app.state.rendermode) ^ 1);
            engine.setRenderMode(app.state.rendermode);
        },
        else => {},
    }
}

fn on_deinit(_: *App) !void {
    std.debug.print("\n", .{});
}
