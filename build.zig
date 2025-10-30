const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.createModule(.{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    switch (target.result.os.tag) {
        .linux => mod.linkSystemLibrary("X11", .{ .needed = true }),
        else => |os| {
            std.debug.print("The {} operating system is not supported.", .{os});
        },
    }
    mod.linkSystemLibrary("GL", .{ .needed = true });
    mod.linkSystemLibrary("GLU", .{ .needed = true });

    const lib = b.addLibrary(.{
        .name = "gaming",
        .root_module = mod,
        .linkage = .static,
    });
    
    b.installArtifact(lib);

    // Run test game
    const game_mod = b.createModule(.{
        .root_source_file = b.path("test_game/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    game_mod.addImport("engine", mod);

    const game_exe = b.addExecutable(.{
        .name = "game test",
        .root_module = game_mod,
    });
    const run_exe = b.addRunArtifact(game_exe);
    
    const run_step = b.step("run", "Run a test game");
    run_step.dependOn(&run_exe.step);
}
