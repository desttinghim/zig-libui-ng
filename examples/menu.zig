const std = @import("std");
const ui = @import("ui");

pub fn on_closing(_: *ui.Window, _: ?*void) ui.Error!ui.Window.ClosingAction {
    ui.Quit();
    return .should_close;
}

pub fn on_should_quit(main_window_opt: ?*ui.Window) ui.Error!ui.QuitAction {
    const main_window = main_window_opt orelse return error.LibUINullUserdata;
    main_window.as_control().Destroy();
    return .should_quit;
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

    const menu = try ui.Menu.New("File");
    _ = try menu.AppendQuitItem();

    const main_window = try ui.Window.New("Menu", 240, 160, .show_menubar);
    main_window.SetMargined(true);
    main_window.SetResizeable(false);

    main_window.SetChild((try ui.Label.New(
        \\This example demonstrates
        \\how to use libui to create
        \\a window with a menubar.
    )).as_control());

    main_window.as_control().Show();
    main_window.OnClosing(void, ui.Error, on_closing, null);

    ui.OnShouldQuit(ui.Window, ui.Error, on_should_quit, main_window);

    ui.Main();
}
