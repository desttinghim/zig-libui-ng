# libui-ng bindings in zig

This repository is a work in progress. Libui-ng is a c library for creating
cross-platform applications using the native widget toolkits for each platform.
These bindings are a manual cleanup of the cimport of `ui.h`. Each control
type has been made an opaque with the extern functions embedded within in them.
Additionally, functions using boolean values have been converted to use `bool`.
Some helper functions have been made for writing event handlers.

## Example
```zig
const std = @import("std");
const ui = @import("ui");

pub fn on_closing(_: *ui.Window, _: ?*void) ui.Window.ClosingAction {
    ui.Quit();
    return .should_close;
}

pub fn main() !void {
    var init_data = ui.InitData{
        .options = .{ .Size = 0 },
    };
    ui.Init(&init_data) catch {
        std.debug.print("Error initializing LibUI: {s}\n", .{init_data.get_error()});
        init_data.free_error();
        return;
    };
    defer ui.Uninit();

    const main_window = try ui.Window.New("Hello, World!", 320, 240, .hide_menubar);

    main_window.as_control().Show();
    main_window.OnClosing(void, on_closing, null);

    main_window.MsgBox("Message Box", "Hello, World!");

    ui.Main();
}
```

## Planned Features
- [x] Comptime function for defining a `Table` based on a struct
- [ ] Nicer bindings for event callbacks
- [ ] More examples
- [ ] Project Template
