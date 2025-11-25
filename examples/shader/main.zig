//! Demonstrates basic mesh/shader loading and rendering
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

    // TEMP
    const verts = [_]f32{
        // positions
        -0.5, -0.5, 0.0,    // bottom left
         0.5, -0.5, 0.0,    // bottom right
         0.5,  0.5, 0.0,    // top right
        -0.5,  0.5, 0.0,    // top left
    };
    const uvs = [_]f32{
        0.0, 0.0,
        1.0, 0.0,
        1.0, 1.0,
        0.0, 1.0,
    };
    const indices = [_]c_uint{
        0, 1, 3,
        1, 2, 3,
    };
    try assets.put("quad", engine.Mesh.init(&verts, &uvs, &indices));
    app.state.quad = assets.getNamed(engine.Mesh, "quad").?;

    const verts2 = [_]f32{
        -0.5, -0.5, 0.0,
         0.5, -0.5, 0.0,
         0.0,  0.5, 0.0,
    };
    const uvs2 = [_]f32{
        0.0, 0.0,
        1.0, 0.0,
        0.5, 1.0,
    };
    try assets.put("tri", engine.Mesh.init(&verts2, &uvs2, &.{0,1,2}));
    app.state.tri = assets.getNamed(engine.Mesh, "tri").?;

    std.debug.print("\nPress F1 to switch between solid and line rendering\n", .{});
    std.debug.print("Press F3 to toggle FPS counter\n", .{});
}

var avrg_fps: f64 = 0;
var frames: f64 = 0;
var show_fps: bool = false;
fn on_update(app: *App) !void {
    const timeSine = @sin(app.time.totalRuntime());
    app.state.fancy_mat.setUniform("timeSine", timeSine);

    app.state.quad.draw(app.state.default_mat);
    app.state.tri.draw(app.state.fancy_mat);

    const time = app.time.totalRuntime();
    const rotate = engine.math.Mat4.fromArrays(.{
        .{@cos(time), @sin(time), 0, 0},
        .{-@sin(time), @cos(time), 0, 0},
        .{0,0,1,0},
        .{0,0,0,1},
    });
    const translate = engine.math.Mat4.fromArrays(.{
        .{1,0,0,0},
        .{0,1,0,0},
        .{0,0,1,0},
        .{timeSine, timeSine, 1, 1},
    });
    const scale = engine.math.Mat4.fromVecs(.{
        engine.math.Vec4f.new(1,0,0,0).mul(timeSine),
        engine.math.Vec4f.new(0,1,0,0).mul(timeSine),
        engine.math.Vec4f.new(0,0,1,0).mul(timeSine),
        engine.math.Vec4f.new(0,0,0,1),
    });
    app.state.fancy_mat.setUniform("transform", translate.mulMatrix(rotate).mulMatrix(scale));

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
