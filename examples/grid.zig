const std = @import("std");
const ui = @import("ui");

pub fn on_closing(_: *ui.Window, _: ?*void) !ui.Window.ClosingAction {
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

    // Create widgets
    const main_window = try ui.Window.New("Hello, World!", 320, 240, .hide_menubar);
    const grid = try ui.Grid.New();
    const ctrl1 = try ui.Button.New("Control 1");
    const ctrl2 = try ui.Button.New("Control 2");
    const ctrl3 = try ui.Button.New("Control 3");
    const ctrl4 = try ui.Button.New("Control 4");
    const ctrl5 = try ui.Button.New("Control 5");

    // Layout
    main_window.SetChild(grid.as_control());
    grid.append(ctrl1.as_control(), .{ .left = 0, .top = 0 }, .{ .xspan = 2, .hexpand = true, .vexpand = true });
    grid.append(ctrl2.as_control(), .{ .left = 2, .top = 0 }, .{ .yspan = 2, .hexpand = true, .vexpand = true });
    grid.append(ctrl3.as_control(), .{ .left = 0, .top = 1 }, .{ .xspan = 2, .hexpand = true, .vexpand = true });
    grid.append(ctrl4.as_control(), .{ .left = 0, .top = 2 }, .{ .hexpand = true, .vexpand = true });
    grid.append(ctrl5.as_control(), .{ .left = 1, .top = 2 }, .{ .xspan = 2, .hexpand = true, .vexpand = true });

    // Set properties, connect callbacks
    // grid.SetPadded(true);
    main_window.OnClosing(void, ui.Error, on_closing, null);
    main_window.as_control().Show();

    // Run
    ui.Main();
}
