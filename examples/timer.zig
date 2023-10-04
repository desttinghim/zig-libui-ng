const std = @import("std");
const ui = @import("ui");

pub const App = struct {
    entry: *ui.MultilineEntry,
};

pub fn main() !void {
    var init_options = ui.InitData{ .options = .{ .Size = 0 } };
    ui.Init(&init_options) catch |e| {
        std.debug.print("Error initializing libui: {s}\n", .{init_options.get_error()});
        init_options.free_error();
        return e;
    };
    const window = try ui.Window.New("Hello", 320, 240, .hide_menubar);
    window.SetMargined(true);

    const box = try ui.Box.New(.Vertical);
    box.SetPadded(true);
    window.SetChild(box.as_control());

    const entry = try ui.MultilineEntry.New(.Wrapping);
    entry.SetReadOnly(true);

    var app = App{
        .entry = entry,
    };

    const button = try ui.Button.New("Say Something");
    button.OnClicked(App, say_something, &app);
    box.Append(button.as_control(), .dont_stretch);

    box.Append(entry.as_control(), .stretch);

    ui.Timer(1000, say_time, &app);

    window.OnClosing(void, on_closing, null);

    window.as_control().Show();

    ui.Main();
}

pub fn say_time(app_opt: ?*anyopaque) callconv(.C) ui.TimerAction {
    const app: *App = @alignCast(@ptrCast(app_opt orelse @panic("Null userdata pointer")));
    const time = std.time.timestamp();
    var buffer = [_]u8{0} ** 64;
    const string = std.fmt.bufPrintZ(&buffer, "The current timestamp is: {}\n", .{time}) catch @panic("Error formatting text.");
    app.entry.Append(string.ptr);
    return .rearm;
}

pub fn on_closing(_: *ui.Window, _: ?*void) ui.Window.ClosingAction {
    ui.Quit();
    return .should_close;
}

pub fn say_something(_: *ui.Button, app_opt: ?*App) void {
    const app = app_opt orelse @panic("Null userdata pointer");
    app.entry.Append("Saying something\n");
}
