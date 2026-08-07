const std = @import("std");
const builtin = @import("builtin");

const LinkMode = std.builtin.LinkMode;

const BuildVars = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    link_mode: std.builtin.LinkMode,
};

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const link_mode = b.option(LinkMode, "link", "Link mode to build libui with") orelse .static;

    const vars = BuildVars{
        .target = target,
        .optimize = optimize,
        .link_mode = link_mode,
    };

    const libui = buildLibUi(b, vars);
    buildExamples(b, vars, libui);
    buildTests(b, vars, libui);

    const ui_module = b.addModule("ui", .{
        .root_source_file = b.path("src/ui.zig"),
    });
    ui_module.linkLibrary(libui);

    const ui_extras_module = b.addModule("ui-extras", .{
        .root_source_file = b.path("src/extras.zig"),
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
            .root_module = b.createModule(.{
                .root_source_file = b.path("examples/" ++ example_name ++ ".zig"),
                .target = target,
                .optimize = optimize,
            }),
            .win32_manifest = b.path(if (is_dynamic)
                "examples/example.manifest"
            else
                "examples/example.static.manifest"),
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

pub fn buildLibUi(b: *std.Build, vars: BuildVars) *std.Build.Step.Compile {
    const target: std.Build.ResolvedTarget = vars.target;
    const optimize: std.builtin.OptimizeMode = vars.optimize;
    const link_mode: LinkMode = vars.link_mode;

    const dep_libui = b.dependency("libui", .{});

    const ui_module = b.addModule("ui", .{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    ui_module.addIncludePath(dep_libui.path("common"));
    ui_module.addCMacro("libui_EXPORTS", "");
    ui_module.addCSourceFiles(.{
        .root = dep_libui.path(""),
        .files = &libui_common_sources,
        .flags = &.{},
    });

    const lib =
        b.addLibrary(.{
            .name = "ui",
            .root_module = ui_module,
            .linkage = link_mode,
        });
    lib.installHeader(dep_libui.path("ui.h"), "ui.h");

    if (target.result.isDarwinLibC()) {
        // use darwin/*.m backend
        lib.installHeader(dep_libui.path("ui_darwin.h"), "ui_darwin.h");
        ui_module.addIncludePath(dep_libui.path("darwin"));
        ui_module.linkFramework("Foundation", .{});
        ui_module.linkFramework("Appkit", .{});
        ui_module.addSystemIncludePath(dep_libui.path("Cocoa"));
        ui_module.addCSourceFiles(.{
            .root = dep_libui.path(""),
            .files = &libui_darwin_sources,
            .flags = &.{},
        });
    } else if (target.result.os.tag == .windows) {
        // use windows/*.cpp backend
        lib.installHeader(dep_libui.path("ui_windows.h"), "ui_windows.h");
        lib.subsystem = .Windows;
        ui_module.addIncludePath(dep_libui.path("windows"));
        ui_module.linkSystemLibrary("user32", .{});
        ui_module.linkSystemLibrary("kernel32", .{});
        ui_module.linkSystemLibrary("gdi32", .{});
        ui_module.linkSystemLibrary("comctl32", .{});
        ui_module.linkSystemLibrary("uxtheme", .{});
        ui_module.linkSystemLibrary("msimg32", .{});
        ui_module.linkSystemLibrary("comdlg32", .{});
        ui_module.linkSystemLibrary("d2d1", .{});
        ui_module.linkSystemLibrary("dwrite", .{});
        ui_module.linkSystemLibrary("ole32", .{});
        ui_module.linkSystemLibrary("oleaut32", .{});
        ui_module.linkSystemLibrary("oleacc", .{});
        ui_module.linkSystemLibrary("uuid", .{});
        ui_module.linkSystemLibrary("windowscodecs", .{});
        ui_module.link_libcpp = true;

        // Compile
        if (link_mode == .dynamic) {
            ui_module.addWin32ResourceFile(.{
                .file = dep_libui.path("windows/resources.rc"),
                .flags = &.{},
            });
        }

        ui_module.addCSourceFiles(.{
            .root = dep_libui.path(""),
            .files = &libui_windows_sources,
            .flags = if (link_mode == .dynamic) &.{} else &.{"-D_UI_STATIC"},
        });
    } else {
        // assume unix/*.c backend
        lib.installHeader(dep_libui.path("ui_unix.h"), "ui_unix.h");
        ui_module.linkSystemLibrary("gtk+-3.0", .{});
        ui_module.addIncludePath(dep_libui.path("unix"));
        ui_module.addCSourceFiles(.{
            .root = dep_libui.path(""),
            .files = &libui_unix_sources,
            .flags = &.{},
        });
    }

    b.installArtifact(lib);

    return lib;
}

pub fn buildExamples(b: *std.Build, vars: BuildVars, libui: *std.Build.Step.Compile) void {
    const target: std.Build.ResolvedTarget = vars.target;
    const optimize: std.builtin.OptimizeMode = vars.optimize;
    const link_mode: LinkMode = vars.link_mode;
    const dep_libui = b.dependency("libui", .{});

    // Build examples
    const examples_step = b.step("examples", "Build all examples");
    const example_names = [_][]const u8{
        "controlgallery",
        "datetime",
        "drawtext",
        "hello-world",
        "histogram",
        "timer",
        "window",
        "cpp-multithread",
    };
    inline for (example_names) |name| {
        const is_cpp = comptime std.mem.startsWith(u8, name, "cpp");
        const main = if (is_cpp) "/main.cpp" else "/main.c";
        const module = b.addModule(name, .{
            .target = target,
            .optimize = optimize,
            .link_libcpp = is_cpp,
        });
        module.addCSourceFile(.{
            .file = dep_libui.path("examples/" ++ name ++ main),
            .flags = &.{},
        });
        module.linkLibrary(libui);
        module.addWin32ResourceFile(.{
            .file = dep_libui.path("examples/resources.rc"),
            .flags = if (link_mode == .dynamic) &.{} else &.{ "/d", "_UI_STATIC" },
        });
        const exe = b.addExecutable(.{
            .name = name,
            .root_module = module,
        });
        const install_step = b.addInstallArtifact(exe, .{});
        const build_step = b.step("example-" ++ name, "Builds the " ++ name ++ " example");
        build_step.dependOn(&install_step.step);
        examples_step.dependOn(&install_step.step);

        const run = b.addRunArtifact(exe);
        const run_step = b.step("example-" ++ name ++ "-run", "Runs the " ++ name ++ " example");
        run_step.dependOn(&run.step);
    }
}

fn buildTests(b: *std.Build, vars: BuildVars, libui: *std.Build.Step.Compile) void {
    const target: std.Build.ResolvedTarget = vars.target;
    const optimize: std.builtin.OptimizeMode = vars.optimize;
    const link_mode: LinkMode = vars.link_mode;
    const dep_libui = b.dependency("libui", .{});

    // Build test step
    const build_all_tests_step = b.step("tests", "Build all test executables (test, unit, qa)");
    const test_dir: std.Build.InstallDir = .{ .custom = "test" };
    {
        const module = b.addModule("test", .{
            .target = target,
            .optimize = optimize,
        });
        module.addCSourceFiles(.{
            .files = &libui_test_sources,
            .flags = &.{},
        });
        module.linkLibrary(libui);

        const exe = b.addExecutable(.{
            .name = "test",
            .root_module = module,
            .win32_manifest = dep_libui.path(if (link_mode == .dynamic) "test/test.manifest" else "test/test.static.manifest"),
        });

        const install = b.addInstallArtifact(exe, .{
            .dest_dir = .{ .override = test_dir },
        });

        const tester = b.step("test", "Build the test executable");
        tester.dependOn(&install.step);

        build_all_tests_step.dependOn(&install.step);

        const run = b.addRunArtifact(exe);
        const run_step = b.step("test-run", "Runs the test executable");
        run_step.dependOn(&run.step);
    }

    // Build qa binary
    {
        const module = b.addModule("qa", .{
            .target = target,
            .optimize = optimize,
        });
        module.addCSourceFiles(.{
            .files = &libui_qa_sources,
            .flags = &.{},
        });
        module.addIncludePath(dep_libui.path("test/qa/"));
        module.linkLibrary(libui);

        const exe = b.addExecutable(.{
            .name = "qa",
            .root_module = module,
            .win32_manifest = dep_libui.path(if (link_mode == .dynamic) "test/qa/qa.manifest" else "test/qa/qa.static.manifest"),
        });

        const install = b.addInstallArtifact(exe, .{
            .dest_dir = .{ .override = test_dir },
        });

        const install_step = b.step("qa", "Build the qa test executable");
        install_step.dependOn(&install.step);

        build_all_tests_step.dependOn(&install.step);

        const run = b.addRunArtifact(exe);
        const run_step = b.step("qa-run", "Runs the test executable");
        run_step.dependOn(&run.step);
    }
}

const libui_common_sources = [_][]const u8{
    "common/areaevents.c",
    "common/attribute.c",
    "common/attrlist.c",
    "common/attrstr.c",
    "common/control.c",
    "common/debug.c",
    "common/matrix.c",
    "common/opentype.c",
    "common/shouldquit.c",
    "common/table.c",
    "common/tablemodel.c",
    "common/tablevalue.c",
    "common/userbugs.c",
    "common/utf.c",
};

const libui_darwin_sources = [_][]const u8{
    "darwin/aat.m",
    "darwin/alloc.m",
    "darwin/areaevents.m",
    "darwin/area.m",
    "darwin/attrstr.m",
    "darwin/autolayout.m",
    "darwin/box.m",
    "darwin/button.m",
    "darwin/checkbox.m",
    "darwin/colorbutton.m",
    "darwin/combobox.m",
    "darwin/control.m",
    "darwin/datetimepicker.m",
    "darwin/debug.m",
    "darwin/draw.m",
    "darwin/drawtext.m",
    "darwin/editablecombo.m",
    "darwin/entry.m",
    "darwin/event.m",
    "darwin/fontbutton.m",
    "darwin/fontmatch.m",
    "darwin/fonttraits.m",
    "darwin/fontvariation.m",
    "darwin/form.m",
    "darwin/future.m",
    "darwin/graphemes.m",
    "darwin/grid.m",
    "darwin/group.m",
    "darwin/image.m",
    "darwin/label.m",
    "darwin/main.m",
    "darwin/menu.m",
    "darwin/multilineentry.m",
    "darwin/nstextfield.m",
    "darwin/opentype.m",
    "darwin/progressbar.m",
    "darwin/radiobuttons.m",
    "darwin/scrollview.m",
    "darwin/separator.m",
    "darwin/slider.m",
    "darwin/spinbox.m",
    "darwin/stddialogs.m",
    "darwin/tablecolumn.m",
    "darwin/table.m",
    "darwin/tab.m",
    "darwin/text.m",
    "darwin/undocumented.m",
    "darwin/util.m",
    "darwin/window.m",
    "darwin/winmoveresize.m",
};

const libui_windows_sources = [_][]const u8{
    "windows/alloc.cpp",
    "windows/area.cpp",
    "windows/areadraw.cpp",
    "windows/areaevents.cpp",
    "windows/areascroll.cpp",
    "windows/areautil.cpp",
    "windows/attrstr.cpp",
    "windows/box.cpp",
    "windows/button.cpp",
    "windows/checkbox.cpp",
    "windows/colorbutton.cpp",
    "windows/colordialog.cpp",
    "windows/combobox.cpp",
    "windows/container.cpp",
    "windows/control.cpp",
    "windows/d2dscratch.cpp",
    "windows/datetimepicker.cpp",
    "windows/debug.cpp",
    "windows/draw.cpp",
    "windows/drawmatrix.cpp",
    "windows/drawpath.cpp",
    "windows/drawtext.cpp",
    "windows/dwrite.cpp",
    "windows/editablecombo.cpp",
    "windows/entry.cpp",
    "windows/events.cpp",
    "windows/fontbutton.cpp",
    "windows/fontdialog.cpp",
    "windows/fontmatch.cpp",
    "windows/form.cpp",
    "windows/graphemes.cpp",
    "windows/grid.cpp",
    "windows/group.cpp",
    "windows/image.cpp",
    "windows/init.cpp",
    "windows/label.cpp",
    "windows/main.cpp",
    "windows/menu.cpp",
    "windows/multilineentry.cpp",
    "windows/opentype.cpp",
    "windows/parent.cpp",
    "windows/progressbar.cpp",
    "windows/radiobuttons.cpp",
    "windows/separator.cpp",
    "windows/sizing.cpp",
    "windows/slider.cpp",
    "windows/spinbox.cpp",
    "windows/stddialogs.cpp",
    "windows/tab.cpp",
    "windows/table.cpp",
    "windows/tabledispinfo.cpp",
    "windows/tabledraw.cpp",
    "windows/tableediting.cpp",
    "windows/tablemetrics.cpp",
    "windows/tabpage.cpp",
    "windows/text.cpp",
    "windows/utf16.cpp",
    "windows/utilwin.cpp",
    "windows/window.cpp",
    "windows/winpublic.cpp",
    "windows/winutil.cpp",
};

const libui_unix_sources = [_][]const u8{
    "unix/alloc.c",
    "unix/area.c",
    "unix/attrstr.c",
    "unix/box.c",
    "unix/button.c",
    "unix/cellrendererbutton.c",
    "unix/checkbox.c",
    "unix/child.c",
    "unix/colorbutton.c",
    "unix/combobox.c",
    "unix/control.c",
    "unix/datetimepicker.c",
    "unix/debug.c",
    "unix/draw.c",
    "unix/drawmatrix.c",
    "unix/drawpath.c",
    "unix/drawtext.c",
    "unix/editablecombo.c",
    "unix/entry.c",
    "unix/fontbutton.c",
    "unix/fontmatch.c",
    "unix/form.c",
    "unix/future.c",
    "unix/graphemes.c",
    "unix/grid.c",
    "unix/group.c",
    "unix/image.c",
    "unix/label.c",
    "unix/main.c",
    "unix/menu.c",
    "unix/multilineentry.c",
    "unix/opentype.c",
    "unix/progressbar.c",
    "unix/radiobuttons.c",
    "unix/separator.c",
    "unix/slider.c",
    "unix/spinbox.c",
    "unix/stddialogs.c",
    "unix/tab.c",
    "unix/table.c",
    "unix/tablemodel.c",
    "unix/text.c",
    "unix/util.c",
    "unix/window.c",
};

const libui_test_sources = [_][]const u8{
    "test/drawtests.c",
    "test/images.c",
    "test/main.c",
    "test/menus.c",
    "test/page1.c",
    "test/page2.c",
    "test/page3.c",
    "test/page4.c",
    "test/page5.c",
    "test/page6.c",
    "test/page7.c",
    "test/page7a.c",
    "test/page7b.c",
    "test/page7c.c",
    "test/page11.c",
    "test/page12.c",
    "test/page13.c",
    "test/page14.c",
    "test/page15.c",
    "test/page16.c",
    "test/page17.c",
    "test/spaced.c",
};

const libui_unit_sources = [_][]const u8{
    "test/unit/main.c",
    "test/unit/init.c",
    "test/unit/slider.c",
    "test/unit/spinbox.c",
    "test/unit/label.c",
    "test/unit/button.c",
    "test/unit/combobox.c",
    "test/unit/checkbox.c",
    "test/unit/drawmatrix.c",
    "test/unit/radiobuttons.c",
    "test/unit/entry.c",
    "test/unit/menu.c",
    "test/unit/progressbar.c",
};

const libui_qa_sources = [_][]const u8{
    "test/qa/qa.c",
    "test/qa/main.c",
    "test/qa/button.c",
    "test/qa/checkbox.c",
    "test/qa/entry.c",
    "test/qa/label.c",
    "test/qa/window.c",
};
