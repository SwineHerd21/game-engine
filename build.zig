const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "gaming",
        .root_module = mod,
    });
    exe.linkLibC();
    // TODO: select necessary platform lib
    exe.linkSystemLibrary("X11");
    
    b.installArtifact(exe);

    const run_exe = b.addRunArtifact(exe);
    
    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_exe.step);
}
