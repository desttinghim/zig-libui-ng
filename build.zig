const std = @import("std");

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const libui = b.dependency("libui", .{
        .target = target,
        .optimize = optimize,
    });

    // Re-export libui artifact
    b.installArtifact(libui.artifact("ui"));

    const ui_module = b.addModule("ui", .{
        .source_file = .{ .path = "src/ui.zig" },
    });

    {
        const exe = b.addExecutable(.{
            .name = "hello",
            .root_source_file = .{ .path = "examples/hello.zig" },
            .target = target,
            .optimize = optimize,
        });
        exe.addModule("ui", ui_module);
        exe.linkLibrary(libui.artifact("ui"));
        exe.subsystem = std.Target.SubSystem.Windows;

        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(&exe.step);

        const run_step = b.step("run-example-hello", "Run the hello example app");
        run_step.dependOn(&run_cmd.step);
    }

    {
        const exe = b.addExecutable(.{
            .name = "timer",
            .root_source_file = .{ .path = "examples/timer.zig" },
            .target = target,
            .optimize = optimize,
        });
        exe.addModule("ui", ui_module);
        exe.linkLibrary(libui.artifact("ui"));
        exe.subsystem = std.Target.SubSystem.Windows;

        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(&exe.step);

        const run_step = b.step("run-example-timer", "Run the timer example app");
        run_step.dependOn(&run_cmd.step);
    }
}
