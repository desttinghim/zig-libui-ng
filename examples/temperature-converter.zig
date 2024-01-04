const std = @import("std");
const ui = @import("ui");

const Temperature = union(enum) {
    celsius: f64,
    fahrenheit: f64,

    pub fn as_fahrenheit(temperature: Temperature) f64 {
        switch (temperature) {
            .celsius => |c| return c * (9.0 / 5.0) + 32.0,
            .fahrenheit => |f| return f,
        }
    }

    pub fn as_celsius(temperature: Temperature) f64 {
        switch (temperature) {
            .celsius => |c| return c,
            .fahrenheit => |f| return (f - 32.0) * (5.0 / 9.0),
        }
    }
};

var celsius_spinbox: *ui.Spinbox = undefined;
var fahrenheit_spinbox: *ui.Spinbox = undefined;

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

    // Application data
    var current_temperature: Temperature = .{ .celsius = 0.0 };

    // Create objects
    const main_window = try ui.Window.New("Counter", 320, 50, .hide_menubar);
    const hbox = try ui.Box.New(.Horizontal);
    celsius_spinbox = try ui.Spinbox.New(.{ .Integer = .{
        .min = -10_000,
        .max = 1_000_000,
    } });
    fahrenheit_spinbox = try ui.Spinbox.New(.{ .Integer = .{
        .min = -10_000,
        .max = 1_000_000,
    } });

    celsius_spinbox.SetValue(@intFromFloat(current_temperature.as_celsius()));
    fahrenheit_spinbox.SetValue(@intFromFloat(current_temperature.as_fahrenheit()));

    // Padding
    main_window.SetResizeable(false);
    main_window.SetMargined(true);
    hbox.SetPadded(true);

    // Layout
    main_window.SetChild(hbox.as_control());
    hbox.Append(celsius_spinbox.as_control(), .dont_stretch);
    hbox.Append((try ui.Label.New("Celsius")).as_control(), .dont_stretch);
    hbox.Append((try ui.Label.New("=")).as_control(), .dont_stretch);
    hbox.Append(fahrenheit_spinbox.as_control(), .dont_stretch);
    hbox.Append((try ui.Label.New("Fahrenheit")).as_control(), .dont_stretch);

    // Connect event handlers
    main_window.OnClosing(void, on_closing, null);
    celsius_spinbox.OnChanged(on_changed, &current_temperature);
    fahrenheit_spinbox.OnChanged(on_changed, &current_temperature);

    // Show the window
    main_window.as_control().Show();

    ui.Main();
}

pub fn on_closing(_: *ui.Window, _: ?*void) ui.Window.ClosingAction {
    ui.Quit();
    return .should_close;
}

pub fn on_changed(spinbox: ?*ui.Spinbox, data: ?*anyopaque) callconv(.C) void {
    const current_temperature: *Temperature = @ptrCast(@alignCast(data));
    if (spinbox == celsius_spinbox) {
        current_temperature.* = .{ .celsius = @floatFromInt(celsius_spinbox.Value()) };
        fahrenheit_spinbox.SetValue(@intFromFloat(current_temperature.as_fahrenheit()));
    } else if (spinbox == fahrenheit_spinbox) {
        current_temperature.* = .{ .fahrenheit = @floatFromInt(fahrenheit_spinbox.Value()) };
        celsius_spinbox.SetValue(@intFromFloat(current_temperature.as_celsius()));
    }
}
