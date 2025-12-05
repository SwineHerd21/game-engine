//! Demonstrates basic mesh/shader loading, matrix math and rendering
//!
//! Press F1 to switch between solid and line rendering
//! Press F3 to enable FPS counter

const std = @import("std");

const Engine = @import("engine");
const math = Engine.math;
const Mat4 = math.Mat4;

const asset_folder = "examples/cube/assets/";

pub fn main() !void {
    std.debug.print("gaming\n", .{});

    const config: Engine.Options = .{
        .title = "Gaming",
        .window_width = 800,
        .window_height = 600,
    };
    var state: State = undefined;
    state.rendermode = .Solid;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var app = try Engine.init(config);
    defer app.deinit();

    // Initialization
    const vs = try Engine.io.loadShader(allocator, asset_folder++"cube.vert", .vertex);
    defer vs.deinit();
    const fs = try Engine.io.loadShader(allocator, asset_folder++"cube.frag", .fragment);
    defer fs.deinit();
    const cat = try Engine.io.loadTexture(allocator, asset_folder++"cat.png");
    defer cat.deinit();
    state.material = try Engine.Material.init(vs, fs, cat);
    defer state.material.deinit();

    state.perspective = Mat4.perspective(45, 800.0/600.0, 0.1, 100);
    state.material.setUniform("projection", state.perspective);

    // TEMP
    const verts = [_]f32{
        // front face
        -0.5, -0.5,  0.5,    0.0, 0.0,  // bottom left
         0.5, -0.5,  0.5,    1.0, 0.0,  // bottom right
         0.5,  0.5,  0.5,    1.0, 1.0,  // top right
        -0.5,  0.5,  0.5,    0.0, 1.0,  // top left
        // back face
        -0.5, -0.5, -0.5,    0.0, 0.0,  // bottom left
         0.5, -0.5, -0.5,    1.0, 0.0,  // bottom right
         0.5,  0.5, -0.5,    1.0, 1.0,  // top right
        -0.5,  0.5, -0.5,    0.0, 1.0,  // top left
    };
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
    state.cube = Engine.Mesh.init(&verts, &indices);
    defer state.cube.deinit();

    std.debug.print("\nPress F1 to switch between solid and line rendering\n", .{});
    std.debug.print("Press F3 to toggle FPS counter\n", .{});

    try app.run(State, &state, on_update, on_event);
}

const State = struct {
    cube: Engine.Mesh,
    material: Engine.Material,
    rendermode: Engine.RenderMode,
    perspective: Mat4,

    cube_pos: math.Vec3f = .zero,
    cube_angle: f32 = 0,
    jumping: bool = false,
};

var avrg_fps: f64 = 0;
var frames: f64 = 0;
var show_fps: bool = false;

fn on_update(app: *Engine, state: *State) !void {
    const time = app.time.totalRuntime();
    const timeSine = @sin(time);
    state.material.setUniform("timeSine", timeSine);

    const radius = 5;
    const camX = timeSine * radius;
    const camZ = @cos(time) * radius;
    const view = Mat4.lookAt(.new(camX, 0, camZ), .zero, .up);
    state.material.setUniform("view", view);

    const scale_factor = (@abs(timeSine)+1)/4;
    const translate = Mat4.translation(.new(0, 0, 1));
    const rotate = Mat4.rotation(.new(1, 1, 1), time);
    const scale = Mat4.scaling(.splat(scale_factor));

    const transform = Mat4.mulBatch(&.{translate,rotate,scale});
    state.material.setUniform("transform", transform);

    state.cube.draw(state.material);

    if (state.jumping) {
        state.cube_pos.y += 3 * app.time.deltaTime();
        state.cube_angle += 2*std.math.pi * (3.0)*app.time.deltaTime();
        if (state.cube_pos.y >= 0.5) state.jumping = false;
    } else if (state.cube_pos.y > 0) {
        state.cube_pos.y -= 3 * app.time.deltaTime();
        state.cube_angle += 2*std.math.pi * (3.0)*app.time.deltaTime();
    } else {
        state.cube_pos.y = 0;
    }
    const big_translate = Mat4.translation(state.cube_pos);
    const big_rotate = Mat4.rotation(.forward, state.cube_angle);
    const big_transform = Mat4.mulBatch(&.{big_translate,big_rotate});
    state.material.setUniform("transform", big_transform);
    state.cube.draw(state.material);

    const cur_fps = 1/app.time.deltaTime();
    avrg_fps = (frames*avrg_fps + cur_fps) / (frames + 1);
    frames += 1;
    if (show_fps) {
        std.debug.print("\rAverage FPS: {}; Current FPS: {}", .{avrg_fps, cur_fps});
    }
}

fn on_event(app: *Engine, state: *State, event: Engine.Event) !void {
    _=app;
    switch (event) {
        .key_press => |ev| {
            if (ev.key == .Space) {
                if (state.jumping) return;
                state.jumping = true;
            }
            if (ev.action == .Repeat) return;
            switch (ev.key) {
                .F1 => {
                    // Switch between solid and wireframe rendering
                    state.rendermode = @enumFromInt(@intFromEnum(state.rendermode) ^ 1);
                    Engine.setRenderMode(state.rendermode);
                },
                .F3 => {
                    std.debug.print("\n", .{});
                    show_fps = !show_fps;
                },
                else => return,
            }
        },
        .window_resize => |ev| {
            const w: f32 = @floatFromInt(ev.width);
            const h: f32 = @floatFromInt(ev.height);
            state.perspective = Mat4.perspective(45, w/h, 0.1, 100);
            state.material.setUniform("projection", state.perspective);
        },
        else => {},
    }
}

