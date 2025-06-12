const std = @import("std");
const ui = @import("ui");

var global_app: App = undefined;

const App = struct {
    main_window: *ui.Window,
    spinbox: *ui.Spinbox,
    slider: *ui.Slider,
    progress_bar: *ui.ProgressBar,
    open_file_entry: *ui.Entry,
    open_folder_entry: *ui.Entry,
    save_file_entry: *ui.Entry,
};

fn on_closing(_: *ui.Window, _: ?*void) ui.Error!ui.Window.ClosingAction {
    ui.Quit();
    return .should_close;
}

fn on_should_quit(main_window_opt: ?*ui.Window) ui.Error!ui.QuitAction {
    const main_window = main_window_opt orelse return error.LibUINullUserdata;
    main_window.as_control().Destroy();
    return .should_quit;
}

fn make_basic_controls_page() !*ui.Control {
    const vbox = try ui.Box.New(.Vertical);
    vbox.SetPadded(true);

    const hbox = try ui.Box.New(.Horizontal);
    hbox.SetPadded(true);
    vbox.Append(hbox.as_control(), .dont_stretch);

    hbox.Append(
        (try ui.Button.New("Button")).as_control(),
        .dont_stretch);
    hbox.Append(
        (try ui.Checkbox.New("Checkbox")).as_control(),
        .dont_stretch);

    vbox.Append(
        (try ui.Label.New("This is a label.\nLabels can span multiple lines.")).as_control(),
        .dont_stretch);
    vbox.Append(
        (try ui.Separator.New(.Horizontal)).as_control(),
        .dont_stretch);

    const group = try ui.Group.New("Entries");
    group.SetMargined(true);
    vbox.Append(group.as_control(), .stretch);

    const entry_form = try ui.Form.New();
    entry_form.SetPadded(true);
    group.SetChild(entry_form.as_control());

    entry_form.Append(
        "Entry",
        (try ui.Entry.New(.Entry)).as_control(),
        .dont_stretch);
    entry_form.Append(
        "Password Entry",
        (try ui.Entry.New(.Password)).as_control(),
        .dont_stretch);
    entry_form.Append(
        "Search Entry",
        (try ui.Entry.New(.Search)).as_control(),
        .dont_stretch);
    entry_form.Append(
        "Multiline Entry",
        (try ui.MultilineEntry.New(.Wrapping)).as_control(),
        .stretch);
    entry_form.Append(
        "Multiline Entry No Wrap",
        (try ui.MultilineEntry.New(.NonWrapping)).as_control(),
        .stretch);

    return vbox.as_control();
}

fn on_spinbox_changed(s: *ui.Spinbox, app_opt: ?*App) ui.Error!void {
    const app = app_opt orelse return error.LibUINullUserdata;
    app.slider.SetValue(s.Value());
    app.progress_bar.SetValue(s.Value());
}

fn on_slider_changed(s: *ui.Slider, app_opt: ?*App) ui.Error!void {
    const app = app_opt orelse return error.LibUINullUserdata;
    app.spinbox.SetValue(s.Value());
    app.progress_bar.SetValue(s.Value());
}

fn make_numbers_page(app: *App) !*ui.Control {
    const hbox = try ui.Box.New(.Horizontal);
    hbox.SetPadded(true);

    const numbers_group = try ui.Group.New("Numbers");
    numbers_group.SetMargined(true);
    hbox.Append(numbers_group.as_control(), .stretch);

    const numbers_vbox = try ui.Box.New(.Vertical);
    numbers_vbox.SetPadded(true);
    numbers_group.SetChild(numbers_vbox.as_control());

    app.spinbox = try ui.Spinbox.New(.{ .Integer = .{
        .min = 0,
        .max = 100,
    }});
    app.slider = try ui.Slider.New(.{ .Integer = .{
        .min = 0,
        .max = 100,
    }});
    app.progress_bar = try ui.ProgressBar.New();
    app.spinbox.OnChanged(App, ui.Error, on_spinbox_changed, app);
    app.slider.OnChanged(App, ui.Error, on_slider_changed, app);
    numbers_vbox.Append(app.spinbox.as_control(), .dont_stretch);
    numbers_vbox.Append(app.slider.as_control(), .dont_stretch);
    numbers_vbox.Append(app.progress_bar.as_control(), .dont_stretch);

    const indeterminate_pb = try ui.ProgressBar.New();
    indeterminate_pb.SetValue(-1);
    numbers_vbox.Append(indeterminate_pb.as_control(), .dont_stretch);

    const lists_group = try ui.Group.New("Lists");
    lists_group.SetMargined(true);
    hbox.Append(lists_group.as_control(), .stretch);

    const lists_vbox = try ui.Box.New(.Vertical);
    lists_vbox.SetPadded(true);
    lists_group.SetChild(lists_vbox.as_control());

    const cbox = try ui.Combobox.New();
    cbox.Append("Combobox Item 1");
    cbox.Append("Combobox Item 2");
    cbox.Append("Combobox Item 3");
    lists_vbox.Append(cbox.as_control(), .dont_stretch);

    const ecbox = try ui.EditableCombobox.New();
    ecbox.Append("Editable Item 1");
    ecbox.Append("Editable Item 2");
    ecbox.Append("Editable Item 3");
    lists_vbox.Append(ecbox.as_control(), .dont_stretch);

    const rb = try ui.RadioButtons.New();
    rb.Append("Radio Button 1");
    rb.Append("Radio Button 2");
    rb.Append("Radio Button 3");
    lists_vbox.Append(rb.as_control(), .dont_stretch);

    return hbox.as_control();
}

fn on_open_file_clicked(_: *ui.Button, app_opt: ?*App) ui.Error!void {
    const app = app_opt orelse return error.LibUINullUserdata;
    const filename =
        app.main_window.OpenFile() orelse {
            app.open_file_entry.SetText("(cancelled)");
            return;
        };
    app.open_file_entry.SetText(filename);
    ui.FreeText(filename);
}

fn on_open_folder_clicked(_: *ui.Button, app_opt: ?*App) ui.Error!void {
    const app = app_opt orelse return error.LibUINullUserdata;
    const filename =
        app.main_window.OpenFolder() orelse {
            app.open_folder_entry.SetText("(cancelled)");
            return;
        };
    app.open_folder_entry.SetText(filename);
    ui.FreeText(filename);
}

fn on_save_file_clicked(_: *ui.Button, app_opt: ?*App) ui.Error!void {
    const app = app_opt orelse return error.LibUINullUserdata;
    const filename =
        app.main_window.SaveFile() orelse {
            app.save_file_entry.SetText("(cancelled)");
            return;
        };
    app.save_file_entry.SetText(filename);
    ui.FreeText(filename);
}

fn on_msg_box_clicked(_: *ui.Button, app_opt: ?*App) ui.Error!void {
    const app = app_opt orelse return error.LibUINullUserdata;
    app.main_window.MsgBox(
        "This is a normal message box.",
        "More detailed information can be shown here.");
}

fn on_msg_box_error_clicked(_: *ui.Button, app_opt: ?*App) ui.Error!void {
    const app = app_opt orelse return error.LibUINullUserdata;
    app.main_window.MsgBox(
        "This message box describes an error.",
        "More detailed information can be shown here.");
}

fn make_data_choosers_page(app: *App) !*ui.Control {
    const hbox = try ui.Box.New(.Horizontal);
    hbox.SetPadded(true);

    const left_vbox = try ui.Box.New(.Vertical);
    left_vbox.SetPadded(true);
    hbox.Append(left_vbox.as_control(), .dont_stretch);

    left_vbox.Append(
        (try ui.DateTimePicker.New(.Date)).as_control(),
        .dont_stretch);
    left_vbox.Append(
        (try ui.DateTimePicker.New(.Time)).as_control(),
        .dont_stretch);
    left_vbox.Append(
        (try ui.DateTimePicker.New(.DateTime)).as_control(),
        .dont_stretch);

    left_vbox.Append(
        (try ui.FontButton.New()).as_control(),
        .dont_stretch);
    left_vbox.Append(
        (try ui.ColorButton.New()).as_control(),
        .dont_stretch);

    hbox.Append(
        (try ui.Separator.New(.Vertical)).as_control(),
        .dont_stretch);

    const right_vbox = try ui.Box.New(.Vertical);
    right_vbox.SetPadded(true);
    hbox.Append(right_vbox.as_control(), .stretch);

    const entry_grid = try ui.Grid.New();
    entry_grid.SetPadded(true);
    right_vbox.Append(entry_grid.as_control(), .dont_stretch);

    const open_file_button = try ui.Button.New("  Open File  ");
    const open_file_entry = try ui.Entry.New(.Entry);
    app.open_file_entry = open_file_entry;
    open_file_entry.SetReadOnly(true);
    open_file_button.OnClicked(App, ui.Error, on_open_file_clicked, app);
    entry_grid.Append(
        open_file_button.as_control(),
        0, 0, 1, 1,
        0, .Fill, 0, .Fill);
    entry_grid.Append(
        open_file_entry.as_control(),
        1, 0, 1, 1,
        1, .Fill, 0, .Fill);

    const open_folder_button = try ui.Button.New("Open Folder");
    const open_folder_entry = try ui.Entry.New(.Entry);
    app.open_folder_entry = open_folder_entry;
    open_folder_entry.SetReadOnly(true);
    open_folder_button.OnClicked(App, ui.Error, on_open_folder_clicked, app);
    entry_grid.Append(
        open_folder_button.as_control(),
        0, 1, 1, 1,
        0, .Fill, 0, .Fill);
    entry_grid.Append(
        open_folder_entry.as_control(),
        1, 1, 1, 1,
        1, .Fill, 0, .Fill);

    const save_file_button = try ui.Button.New("  Save File  ");
    const save_file_entry = try ui.Entry.New(.Entry);
    app.save_file_entry = save_file_entry;
    save_file_entry.SetReadOnly(true);
    save_file_button.OnClicked(App, ui.Error, on_save_file_clicked, app);
    entry_grid.Append(
        save_file_button.as_control(),
        0, 2, 1, 1,
        0, .Fill, 0, .Fill);
    entry_grid.Append(
        save_file_entry.as_control(),
        1, 2, 1, 1,
        1, .Fill, 0, .Fill);

    const msg_grid = try ui.Grid.New();
    msg_grid.SetPadded(true);
    entry_grid.Append(
        msg_grid.as_control(),
        0, 3, 2, 1,
        0, .Center, 0, .Start);

    const msg_box_button = try ui.Button.New("Message Box");
    msg_box_button.OnClicked(App, ui.Error, on_msg_box_clicked, app);
    msg_grid.Append(
        msg_box_button.as_control(),
        0, 0, 1, 1,
        0, .Fill, 0, .Fill);
    const error_box_button = try ui.Button.New("Error Box");
    error_box_button.OnClicked(App, ui.Error, on_msg_box_error_clicked, app);
    msg_grid.Append(
        error_box_button.as_control(),
        1, 0, 1, 1,
        0, .Fill, 0, .Fill);

    return hbox.as_control();
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

    var app = &global_app;
    app.main_window = try ui.Window.New("libui Control Gallery", 640, 480, .show_menubar);
    app.main_window.OnClosing(void, ui.Error, on_closing, null);
    ui.OnShouldQuit(ui.Window, ui.Error, on_should_quit, app.main_window);

    const tab = try ui.Tab.New();
    app.main_window.SetChild(tab.as_control());
    app.main_window.SetMargined(true);

    tab.Append("Basic Controls", try make_basic_controls_page());
    tab.SetMargined(0, true);

    tab.Append("Numbers and Lists", try make_numbers_page(app));
    tab.SetMargined(1, true);

    tab.Append("Data Choosers", try make_data_choosers_page(app));
    tab.SetMargined(2, true);

    app.main_window.as_control().Show();

    ui.Main();
}
