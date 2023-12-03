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

    const ui_extras_module = b.addModule("ui-extras", .{
        .source_file = .{ .path = "src/extras.zig" },
        .dependencies = &.{.{
            .name = "ui",
            .module = ui_module,
        }},
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

        exe.addWin32ResourceFile(.{
            .file = .{ .path = "examples/resources.rc" },
            .flags = &.{ "/d", "_UI_STATIC" },
        });

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

        exe.addWin32ResourceFile(.{
            .file = .{ .path = "examples/resources.rc" },
            .flags = &.{ "/d", "_UI_STATIC" },
        });

        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(&exe.step);

        const run_step = b.step("run-example-timer", "Run the timer example app");
        run_step.dependOn(&run_cmd.step);
    }

    {
        const exe = b.addExecutable(.{
            .name = "table",
            .root_source_file = .{ .path = "examples/table.zig" },
            .target = target,
            .optimize = optimize,
        });
        exe.addModule("ui", ui_module);
        exe.addModule("ui-extras", ui_extras_module);
        exe.linkLibrary(libui.artifact("ui"));
        exe.subsystem = std.Target.SubSystem.Windows;

        exe.addWin32ResourceFile(.{
            .file = .{ .path = "examples/resources.rc" },
            .flags = &.{ "/d", "_UI_STATIC" },
        });

        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(&exe.step);

        const run_step = b.step("run-example-table", "Run the table example app");
        run_step.dependOn(&run_cmd.step);
    }

    {
        const exe = b.addExecutable(.{
            .name = "counter",
            .root_source_file = .{ .path = "examples/counter.zig" },
            .target = target,
            .optimize = optimize,
        });
        exe.addModule("ui", ui_module);
        exe.linkLibrary(libui.artifact("ui"));
        exe.subsystem = std.Target.SubSystem.Windows;

        exe.addWin32ResourceFile(.{
            .file = .{ .path = "examples/resources.rc" },
            .flags = &.{ "/d", "_UI_STATIC" },
        });

        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(&exe.step);

        const run_step = b.step("run-example-counter", "Run the counter example app");
        run_step.dependOn(&run_cmd.step);
    }

    {
        const exe = b.addExecutable(.{
            .name = "temperature-converter",
            .root_source_file = .{ .path = "examples/temperature-converter.zig" },
            .target = target,
            .optimize = optimize,
        });
        exe.addModule("ui", ui_module);
        exe.linkLibrary(libui.artifact("ui"));
        exe.subsystem = std.Target.SubSystem.Windows;

        exe.addWin32ResourceFile(.{
            .file = .{ .path = "examples/resources.rc" },
            .flags = &.{ "/d", "_UI_STATIC" },
        });

        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(&exe.step);

        const run_step = b.step("run-example-temperature-converter", "Run the temperature converter example app");
        run_step.dependOn(&run_cmd.step);
    }

    {
        const exe = b.addExecutable(.{
            .name = "flight-booker",
            .root_source_file = .{ .path = "examples/flight-booker.zig" },
            .target = target,
            .optimize = optimize,
        });
        exe.addModule("ui", ui_module);
        exe.linkLibrary(libui.artifact("ui"));
        exe.subsystem = std.Target.SubSystem.Windows;

        exe.addWin32ResourceFile(.{
            .file = .{ .path = "examples/resources.rc" },
            .flags = &.{ "/d", "_UI_STATIC" },
        });

        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(&exe.step);

        const run_step = b.step("run-example-flight-booker", "Run the flight booker  example app");
        run_step.dependOn(&run_cmd.step);
    }

    {
        const exe = b.addExecutable(.{
            .name = "crud",
            .root_source_file = .{ .path = "examples/crud.zig" },
            .target = target,
            .optimize = optimize,
        });
        exe.addModule("ui", ui_module);
        exe.addModule("ui-extras", ui_extras_module);
        exe.linkLibrary(libui.artifact("ui"));
        exe.subsystem = std.Target.SubSystem.Windows;

        exe.addWin32ResourceFile(.{
            .file = .{ .path = "examples/resources.rc" },
            .flags = &.{ "/d", "_UI_STATIC" },
        });

        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(&exe.step);

        const run_step = b.step("run-example-crud", "Run the CRUD example app");
        run_step.dependOn(&run_cmd.step);
    }
}
