const std = @import("std");

// Examples TODO:
// Rendering a rotating Utah teapot
// Shaders with complex uniform types

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("engine", .{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    switch (target.result.os.tag) {
        .linux => mod.linkSystemLibrary("X11", .{ .needed = true }),
        else => |os| {
            std.debug.print("The {t} operating system is not supported.", .{os});
        },
    }
    // OpenGL
    mod.linkSystemLibrary("GL", .{ .needed = true });
    const gl_bindings = @import("zigglgen").generateBindingsModule(b, .{
        .api = .gl,
        .version = .@"4.6",
        .profile = .core,
        .extensions = &.{ },
    });
    mod.addImport("gl", gl_bindings);

    // zigimg
    const zigimg = b.dependency("zigimg", .{
        .target = target,
        .optimize = optimize,
    });
    mod.addImport("zigimg", zigimg.module("zigimg"));

    // Run tests
    const test_exe = b.addTest(.{.root_module = mod});
    const run_test = b.addRunArtifact(test_exe);
    run_test.has_side_effects = true;
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_test.step);

    // Run test game
    const game_mod = b.createModule(.{
        .root_source_file = b.path("examples/cube/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    game_mod.addImport("engine", mod);

    const game_exe = b.addExecutable(.{
        .name = "test-game",
        .root_module = game_mod,
    });
    b.installArtifact(game_exe);
    const run_exe = b.addRunArtifact(game_exe);
    
    const run_step = b.step("run", "Run a test game");
    run_step.dependOn(&run_exe.step);
    run_step.dependOn(b.getInstallStep());
}
