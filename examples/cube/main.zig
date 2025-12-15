//! Demonstrates basic mesh/shader loading, matrix math and rendering

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
    state.fullscreen = .windowed;

    var dba: std.heap.DebugAllocator(.{}) = .init;
    defer _=dba.deinit();
    const allocator = dba.allocator();

    var app = try Engine.init(config);
    defer app.deinit();

    // Initialization
    const vs = try Engine.io.loadShader(allocator, asset_folder++"cube.vert", .vertex);
    const fs = try Engine.io.loadShader(allocator, asset_folder++"cube.frag", .fragment);
    var cat = try Engine.io.loadImage(allocator, asset_folder++"cat.png", true);
    // RGB565 format works and actually doesn't look much different!
    try cat.convert(allocator, .rgb565);
    const cat_text = try Engine.Texture.fromImage(cat, .{});
    defer cat_text.deinit();
    state.material = try Engine.Material.init(vs, fs, cat_text);
    defer state.material.deinit();
    // shaders and images can be safely deleted after material creation
    vs.deinit();
    fs.deinit();
    cat.deinit(allocator);

    state.material.use();
    state.perspective = Mat4.perspective(45, 800.0/600.0, 0.1, 100);
    state.material.setUniform("projection", state.perspective);

    const cube_model = try Engine.io.loadModel(allocator, asset_folder++"cube.obj");
    state.cube = Engine.MeshInstance.fromMeshData(cube_model.meshes[0]);
    defer state.cube.deinit();
    cube_model.deinit(allocator);

    const monkey_model = try Engine.io.loadModel(allocator, asset_folder++"suzanne.obj");
    state.monkey = Engine.MeshInstance.fromMeshData(monkey_model.meshes[0]);
    defer state.monkey.deinit();
    monkey_model.deinit(allocator);

    std.debug.print("\nPress F1 to switch between solid and line rendering\n", .{});
    std.debug.print("Press F3 to print current frametime\n", .{});
    std.debug.print("Press F10 to maximize window\n", .{});
    std.debug.print("Press F11 to switch between fullscreen and windowed mode\n\n", .{});


    try app.run(State, &state, on_update, on_event);
}

const State = struct {
    rendermode: Engine.RenderMode,
    fullscreen: Engine.Window.FullscreenMode,
    maximized: bool,

    cube: Engine.MeshInstance,
    material: Engine.Material,
    perspective: Mat4,

    monkey: Engine.MeshInstance,

    cube_pos: math.Vec3f = .zero,
    cube_angle: f32 = 0,
    jumping: bool = false,
};

fn on_update(app: *Engine, state: *State) !void {
    const time = app.time.totalRuntime();
    const timeSine = @sin(time);
    state.material.setUniform("timeSine", timeSine);

    // camera
    const radius = 5;
    const camX = timeSine * radius;
    const camZ = @cos(time) * radius;
    const view = Mat4.lookAt(.new(camX, 0, camZ), .zero, .up);
    state.material.setUniform("view", view);

    // monkey
    const scale_factor = (@abs(timeSine)+1)/8;
    const monkey_translate = Mat4.translation(.new(0, 0, 1));
    const monkey_rotate = Mat4.rotation(.new(1, 1, 1), time);
    const monkey_scale = Mat4.scaling(.splat(scale_factor));

    const monkey_transform = Mat4.mulBatch(&.{monkey_translate,monkey_rotate,monkey_scale});
    state.material.setUniform("transform", monkey_transform);
    state.monkey.draw();

    // cube
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
    const cube_translate = Mat4.translation(state.cube_pos);
    const cube_scale = Mat4.scaling(.splat(0.5));
    const cube_rotate = Mat4.rotation(.forward, state.cube_angle);
    const cube_transform = Mat4.mulBatch(&.{cube_translate,cube_rotate,cube_scale});
    state.material.setUniform("transform", cube_transform);
    state.cube.draw();
}

fn on_event(app: *Engine, state: *State, event: Engine.Event) !void {
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
                    const dt = app.time.deltaTime();
                    std.debug.print("\nFrametime: {}ms; FPS: {}", .{dt*std.time.ms_per_s, 1/dt});
                },
                .F10 => {
                    if (state.fullscreen == .fullscreen) return;
                    state.maximized = !state.maximized;
                    app.window.setMaximized(state.maximized);
                },
                .F11 => {
                    state.fullscreen = @enumFromInt(@intFromEnum(state.fullscreen) ^ 1);
                    app.window.setFullscreenMode(state.fullscreen);
                },
                else => return,
            }
        },
        .window_resize => |ev| {
            const w: f32 = @floatFromInt(ev.width);
            const h: f32 = @floatFromInt(ev.height);
            // Need to adjust camera perspective
            state.perspective = Mat4.perspective(45, w/h, 0.1, 100);
            state.material.setUniform("projection", state.perspective);
        },
        else => {},
    }
}

