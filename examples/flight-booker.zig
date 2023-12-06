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
    const vbox = try ui.Box.New(.Vertical);

    var app = App{
        .flight_type = try ui.Combobox.New(),
        .leave_datetime = try ui.DateTimePicker.New(.Date),
        .leave_status = try ui.Label.New(""),
        .return_datetime = try ui.DateTimePicker.New(.Date),
        .return_status = try ui.Label.New(""),
        .book = try ui.Button.New("Book"),
    };

    // Layout
    main_window.SetMargined(true);
    main_window.SetChild(vbox.as_control());
    vbox.SetPadded(true);
    vbox.Append(app.flight_type.as_control(), .dont_stretch);
    vbox.Append(app.leave_datetime.as_control(), .dont_stretch);
    vbox.Append(app.leave_status.as_control(), .dont_stretch);
    vbox.Append(app.return_datetime.as_control(), .dont_stretch);
    vbox.Append(app.return_status.as_control(), .dont_stretch);
    vbox.Append(app.book.as_control(), .dont_stretch);

    // Widget set up
    app.flight_type.Append("one-way flight");
    app.flight_type.Append("return flight");

    // Connect signals
    main_window.OnClosing(void, on_closing, null);
    app.flight_type.OnSelected(on_flight_type_selected, &app);
    app.leave_datetime.OnChanged(on_leave_changed, &app);
    app.return_datetime.OnChanged(on_return_changed, &app);
    app.book.OnClicked(App, on_booked, &app);

    // Set default flight_type
    app.flight_type.SetSelected(0);

    // Prime state machine, Show window
    try app.run(&.Process);
    main_window.as_control().Show();

    ui.Main();
}

fn on_flight_type_selected(combo: ?*ui.Combobox, data: ?*anyopaque) callconv(.C) void {
    const app: *App = @ptrCast(@alignCast(data));
    const index = combo.?.Selected();
    const value: App.FlightType = switch (index) {
        0 => .one_way,
        1 => .return_flight,
        else => return,
    };
    app.run_handle_error(&.{ .ChangeType = value });
}

fn on_leave_changed(dt: ?*ui.DateTimePicker, data: ?*anyopaque) callconv(.C) void {
    const app: *App = @ptrCast(@alignCast(data));
    const leave_date = dt.?.Time();
    app.run_handle_error(&.{ .ChangeLeaveDate = leave_date });
}

fn on_return_changed(dt: ?*ui.DateTimePicker, data: ?*anyopaque) callconv(.C) void {
    const app: *App = @ptrCast(@alignCast(data));
    const return_date = dt.?.Time();
    app.run_handle_error(&.{ .ChangeReturnDate = return_date });
}

fn on_booked(btn: *ui.Button, app: ?*App) void {
    _ = btn;
    app.?.run_handle_error(&.Book);
}

const App = struct {
    state: *const fn (*App, *const Event) Error!void = _begin,

    // widgets
    flight_type: *ui.Combobox,
    leave_datetime: *ui.DateTimePicker,
    leave_status: *ui.Label,
    return_datetime: *ui.DateTimePicker,
    return_status: *ui.Label,
    book: *ui.Button,

    // data
    leave_date: ?ui.struct_tm = null,
    return_date: ?ui.struct_tm = null,

    const Event = union(enum) {
        ChangeType: FlightType,
        ChangeLeaveDate: ui.struct_tm,
        ChangeReturnDate: ui.struct_tm,
        Book,
        Process,
    };
    const Error = error{};
    const FlightType = enum { one_way, return_flight };

    fn run_handle_error(app: *App, event: *const Event) void {
        app.state(app, event) catch |e| {
            std.debug.print("Error {!} on run!\n", .{e});
            @panic(e);
        };
    }

    fn run(app: *App, event: *const Event) Error!void {
        try app.state(app, event);
    }

    fn _begin(app: *App, event: *const Event) Error!void {
        _ = event;
        app.state = _oneway_flight;
        app.leave_datetime.as_control().Enable();
        app.return_datetime.as_control().Disable();
        app.book.as_control().Disable();
    }

    fn _oneway_flight(app: *App, event: *const Event) Error!void {
        switch (event.*) {
            .ChangeType => |new_type| {
                if (new_type == .return_flight) {
                    app.return_datetime.as_control().Enable();
                    app.book.as_control().Disable();
                    app.state = _return_flight;
                }
            },
            .ChangeLeaveDate => |new_date| {
                app.leave_date = new_date;
                app.leave_status.SetText("");
                app.book.as_control().Enable();
            },
            else => {
                std.log.debug("Unhandled event", .{});
            },
        }

        if (app.leave_date == null) {
            app.leave_status.SetText("");
            app.book.as_control().Disable();
        } else {
            app.leave_status.SetText("");
            app.book.as_control().Enable();
        }
    }

    fn _return_flight(app: *App, event: *const Event) Error!void {
        switch (event.*) {
            .ChangeType => |new_type| {
                if (new_type == .one_way) {
                    app.return_datetime.as_control().Disable();
                    app.book.as_control().Disable();
                    app.state = _oneway_flight;
                }
            },
            .ChangeLeaveDate => |new_date| {
                app.leave_date = new_date;
                app.leave_status.SetText("");
            },
            .ChangeReturnDate => |new_date| {
                app.return_date = new_date;
            },
            else => {
                std.log.debug("Unhandled event", .{});
            },
        }

        enable_book: {
            const leave_date = app.leave_date orelse break :enable_book;
            const return_date = app.return_date orelse break :enable_book;

            if ((leave_date.year < return_date.year) or
                (leave_date.year == return_date.year and leave_date.year_day <= return_date.year_day))
            {
                app.return_status.SetText("");
                app.book.as_control().Enable();
            } else {
                app.return_status.SetText("Return date must come after leave date");
            }
        }
    }
};
