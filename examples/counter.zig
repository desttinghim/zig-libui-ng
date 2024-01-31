const std = @import("std");
const ui = @import("ui");

var counter: usize = 0;

const Error = ui.Error || std.fmt.BufPrintError;

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

    // Create objects
    const main_window = try ui.Window.New("Counter", 0, 0, .hide_menubar);
    const hbox = try ui.Box.New(.Horizontal);
    const label = try ui.Label.New("0");
    const button = try ui.Button.New("Count");

    // Padding
    hbox.SetPadded(true);
    main_window.SetMargined(true);

    // Layout
    hbox.Append(label.as_control(), .stretch);
    hbox.Append(button.as_control(), .stretch);
    main_window.SetChild(hbox.as_control());

    // Connect event handlers
    button.OnClicked(ui.Label, Error, on_clicked, label);
    main_window.OnClosing(void, ui.Error, on_closing, null);

    // Show the window
    main_window.as_control().Show();

    ui.Main();
}

pub fn on_closing(_: *ui.Window, _: ?*void) !ui.Window.ClosingAction {
    ui.Quit();
    return .should_close;
}

pub fn on_clicked(_: *ui.Button, label_opt: ?*ui.Label) Error!void {
    const label = label_opt orelse return error.LibUINullUserdata;
    counter += 1;

    var buf: [255]u8 = undefined;
    const new_string = try std.fmt.bufPrintZ(&buf, "{}", .{counter});

    label.SetText(new_string);
}
