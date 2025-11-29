//! Demonstrates basic mesh/shader loading, matrix math and rendering
//!
//! Press F1 to switch between solid and line rendering
//! Press F3 to enable FPS counter

const std = @import("std");

const engine = @import("engine");

pub fn main() !void {
    std.debug.print("gaming\n", .{});

    const config: engine.Options(State) = .{
        .title = "Gaming",
        .window_width = 800,
        .window_height = 600,
        .asset_folder = "examples/cube/assets/",
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
    cube: engine.Mesh,
    material: engine.Material,
    rendermode: engine.RenderMode,
};
const App = engine.App(State);

fn on_init(app: *App) !void {
    var assets = app.asset_manager;

    app.state.material = try assets.getOrLoad(engine.Material, "cube.mat");

    const projection = engine.math.Mat4.perspective(45, 800.0/600.0, 0.1, 100);
    app.state.material.setUniform("projection", projection);

    // TEMP
    const verts = [_]f32{
        // front face
        -0.5, -0.5, 0.5,    // bottom left
         0.5, -0.5, 0.5,    // bottom right
         0.5,  0.5, 0.5,    // top right
        -0.5,  0.5, 0.5,    // top left
        // back face
        -0.5, -0.5, -0.5,    // bottom left
         0.5, -0.5, -0.5,    // bottom right
         0.5,  0.5, -0.5,    // top right
        -0.5,  0.5, -0.5,    // top left
    };
    const uvs = [_]f32{
        0.0, 0.0,
        1.0, 0.0,
        1.0, 1.0,
        0.0, 1.0,
    } ** 2;
    const indices = [_]c_uint{
        // front face
        0, 1, 3,
        1, 2, 3,
        // back face
        4, 7, 5,
        5, 7, 6,
        // right face
        1, 5, 2,
        5, 6, 2,
        // left face
        0, 3, 4,
        3, 7, 4,
        // top face
        3, 2, 7,
        2, 6, 7,
        // bottom face,
        0, 4, 1,
        4, 5, 1,
    };
    try assets.put("cube", engine.Mesh.init(&verts, &uvs, &indices));
    app.state.cube = assets.getNamed(engine.Mesh, "cube").?;

    std.debug.print("\nPress F1 to switch between solid and line rendering\n", .{});
    std.debug.print("Press F3 to toggle FPS counter\n", .{});
}

var avrg_fps: f64 = 0;
var frames: f64 = 0;
var show_fps: bool = false;
fn on_update(app: *App) !void {
    const time = app.time.totalRuntime();
    const timeSine = @sin(time);
    app.state.material.setUniform("timeSine", timeSine);

    const radius = 5;
    const camX = timeSine * radius;
    const camZ = @cos(time) * radius;
    const view = engine.math.Mat4.lookAt(.new(camX, 0, camZ), .zero, .up);
    app.state.material.setUniform("view", view);

    const scale_factor = (@abs(timeSine)+1)/4;
    const translate = engine.math.Mat4.translation(.new(0, 0, 1));
    const rotate = engine.math.Mat4.rotation(.new(1, 1, 1), time);
    const scale = engine.math.Mat4.scaling(.splat(scale_factor));

    const transform = engine.math.transform(&.{translate,rotate,scale});
    app.state.material.setUniform("transform", transform);

    app.state.cube.draw(app.state.material);

    app.state.material.setUniform("transform", engine.math.Mat4.identity);
    app.state.cube.draw(app.state.material);

    const cur_fps = 1/app.time.deltaTime();
    avrg_fps = (frames*avrg_fps + cur_fps) / (frames + 1);
    frames += 1;
    if (show_fps) {
        std.debug.print("\rAverage FPS: {}; Current FPS: {}", .{avrg_fps, cur_fps});
    }
}

fn on_event(app: *App, event: engine.Event) !void {
    switch (event) {
        .key_press => |ev| {
            if (ev.action == .Repeat) return;
            switch (ev.key) {
                .F1 => {
                    // Switch between solid and wireframe rendering
                    app.state.rendermode = @enumFromInt(@intFromEnum(app.state.rendermode) ^ 1);
                    engine.setRenderMode(app.state.rendermode);
                },
                .F3 => {
                    std.debug.print("\n", .{});
                    show_fps = !show_fps;
                },
                else => return,
            }
        },
        else => {},
    }
}

fn on_deinit(_: *App) !void {
    std.debug.print("\n", .{});
}
