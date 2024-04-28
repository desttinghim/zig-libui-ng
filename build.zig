const std = @import("std");

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const libui = b.dependency("libui", .{
        .target = target,
        .optimize = optimize,
    });

    const ui_module = b.addModule("ui", .{
        .root_source_file = .{ .path = "src/ui.zig" },
    });
    ui_module.linkLibrary(libui.artifact("ui"));

    const ui_extras_module = b.addModule("ui-extras", .{
        .root_source_file = .{ .path = "src/extras.zig" },
        .imports = &.{.{
            .name = "ui",
            .module = ui_module,
        }},
    });

    const check_step = b.step("check", "Build all examples");
    const is_dynamic = false;

    inline for (examples, uses_extras) |example_name, use_extras| {
        const exe = b.addExecutable(.{
            .name = example_name,
            .root_source_file = .{ .path = "examples/" ++ example_name ++ ".zig" },
            .target = target,
            .optimize = optimize,
            .win32_manifest = .{
                .path = if (is_dynamic)
                    "examples/example.manifest"
                else
                    "examples/example.static.manifest",
            },
        });
        exe.root_module.addImport("ui", ui_module);
        if (use_extras) exe.root_module.addImport("ui-extras", ui_extras_module);
        exe.subsystem = std.Target.SubSystem.Windows;

        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(&exe.step);

        const run_step = b.step("run-example-" ++ example_name, "Run the hello example app");
        run_step.dependOn(&run_cmd.step);

        check_step.dependOn(&exe.step);
    }
}

const examples = &[_][]const u8{
    "hello",
    "counter",
    "timer",
    "table",
    "temperature-converter",
    "flight-booker",
    "table-mvc",
    "draw",
    "menu",
    "crud",
    "circle-drawer",
};

const uses_extras = &[_]bool{
    false,
    false,
    false,
    true,
    false,
    false,
    true,
    false,
    false,
    false,
    false,
};
