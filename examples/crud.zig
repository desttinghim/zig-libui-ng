const std = @import("std");
const ui = @import("ui");

var global_app: App = undefined;

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

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    // Initialize components
    const main_window = try ui.Window.New("CRUD", 320, 240, .hide_menubar);
    const vbox = try ui.Box.New(.Vertical);
    const hbox_filter = try ui.Box.New(.Horizontal);
    const hbox_content = try ui.Box.New(.Horizontal);
    const hbox_edit = try ui.Box.New(.Horizontal);
    const vbox_list = try ui.Box.New(.Vertical);
    const form_edit = try ui.Form.New();
    const label_filter = try ui.Label.New("Filter prefix:");
    const entry_filter = try ui.Entry.New(.Search);
    const entry_name = try ui.Entry.New(.Entry);
    const entry_surname = try ui.Entry.New(.Entry);
    const btn_create = try ui.Button.New("Create");
    const btn_update = try ui.Button.New("Update");
    const btn_delete = try ui.Button.New("Delete");

    var app = &global_app;
    app.* = App{
        .data = App.Data.init(gpa.allocator()),
        .data_allocator = gpa.allocator(),
        .list = vbox_list,
        .list_buttons = std.ArrayList(*ui.Button).init(gpa.allocator()),
        .arena_current = std.heap.ArenaAllocator.init(gpa.allocator()),
        .arena_old = std.heap.ArenaAllocator.init(gpa.allocator()),
        .entry_name = entry_name,
        .entry_surname = entry_surname,
    };
    defer app.deinit();

    try app.addDatum("Hans", "Emil");
    try app.addDatum("Max", "Mustermann");
    try app.addDatum("Roman", "Tisch");

    try app.updateList(null);

    // Padding + Margins
    main_window.SetMargined(true);
    vbox.SetPadded(true);
    hbox_filter.SetPadded(true);
    hbox_content.SetPadded(true);
    hbox_edit.SetPadded(true);
    form_edit.SetPadded(true);

    // Layout
    main_window.SetChild(vbox.as_control());

    vbox.Append(hbox_filter.as_control(), .dont_stretch);
    vbox.Append(hbox_content.as_control(), .stretch);
    vbox.Append(hbox_edit.as_control(), .dont_stretch);

    hbox_content.Append(vbox_list.as_control(), .stretch);
    hbox_content.Append(form_edit.as_control(), .stretch);

    hbox_filter.Append(label_filter.as_control(), .dont_stretch);
    hbox_filter.Append(entry_filter.as_control(), .dont_stretch);

    form_edit.Append("Name:", entry_name.as_control(), .dont_stretch);
    form_edit.Append("Surname:", entry_surname.as_control(), .dont_stretch);

    hbox_edit.Append(btn_create.as_control(), .dont_stretch);
    hbox_edit.Append(btn_update.as_control(), .dont_stretch);
    hbox_edit.Append(btn_delete.as_control(), .dont_stretch);

    // Connect
    main_window.OnClosing(App, ui.Error, on_closing, app);
    entry_filter.OnChanged(App, FilterError, on_filter_changed, app);
    btn_create.OnClicked(App, CreateError, on_create, app);
    btn_update.OnClicked(App, UpdateError, on_update, app);
    btn_delete.OnClicked(App, DeleteError, on_delete, app);

    // Show the window and start ui main
    main_window.as_control().Show();
    ui.Main();
}

const App = struct {
    id: usize = 1,
    data: Data,
    data_allocator: std.mem.Allocator,
    list: *ui.Box,
    // We need to store what items are in the list view,
    // because libui expects us to free them when we are
    // done with them.
    list_buttons: std.ArrayList(*ui.Button),
    arena_current: std.heap.ArenaAllocator,
    arena_old: std.heap.ArenaAllocator,
    entry_name: *ui.Entry,
    entry_surname: *ui.Entry,
    current_filter: ?[]const u8 = null,
    selected_id: ?usize = 0,

    const Datum = struct {
        name: []const u8,
        surname: []const u8,
    };

    const Data = std.AutoHashMap(usize, Datum);

    fn deinit(app: *App) void {
        var iter = app.data.valueIterator();
        while (iter.next()) |datum| {
            app.data_allocator.free(datum.name);
            app.data_allocator.free(datum.surname);
        }
        app.list_buttons.deinit();
        app.data.deinit();
        app.arena_current.deinit();
        app.arena_old.deinit();
    }

    const SetSelectedError = std.mem.Allocator.Error;
    fn setSelected(app: *App, selected_id: usize) SetSelectedError!void {
        app.selected_id = null;
        if (selected_id == 0) return;
        const datum = app.data.get(selected_id) orelse return;
        app.selected_id = selected_id;
        const name = try app.arena_current.allocator().dupeZ(u8, datum.name);
        const surname = try app.arena_current.allocator().dupeZ(u8, datum.surname);
        app.entry_name.SetText(name);
        app.entry_surname.SetText(surname);
    }

    const AddDatumError = std.mem.Allocator.Error;
    fn addDatum(app: *App, name: []const u8, surname: []const u8) AddDatumError!void {
        const name_dup = try app.data_allocator.dupe(u8, name);
        const surname_dup = try app.data_allocator.dupe(u8, surname);
        try app.data.put(app.id, .{
            .name = name_dup,
            .surname = surname_dup,
        });
        app.id += 1;
    }

    const SetDatumError = std.mem.Allocator.Error;
    fn setDatum(app: *App, id: usize, name: []const u8, surname: []const u8) !void {
        const name_dup = try app.data_allocator.dupe(u8, name);
        const surname_dup = try app.data_allocator.dupe(u8, surname);
        try app.data.put(id, .{
            .name = name_dup,
            .surname = surname_dup,
        });
    }

    fn deleteDatum(app: *App, id: usize) void {
        app.selected_id = null;
        const kv = app.data.fetchRemove(id) orelse return;
        const datum = kv.value;
        app.data_allocator.free(datum.name);
        app.data_allocator.free(datum.surname);
    }

    fn rotateArenas(app: *App) void {
        const arena = app.arena_old;
        app.arena_old = app.arena_current;
        app.arena_current = arena;
    }

    const ListUpdateError = std.fmt.AllocPrintError || error{InitButton};
    fn updateList(app: *App, filter_text: ?[]const u8) ListUpdateError!void {
        app.rotateArenas();
        if (!app.arena_current.reset(.retain_capacity)) {
            std.log.info("Failed to reset arena", .{});
        }
        const allocator = app.arena_current.allocator();

        var to_clear = app.list.NumChildren();
        while (to_clear != 0) : (to_clear -= 1) {
            app.list.Delete(0);
            const btn = app.list_buttons.orderedRemove(0);
            btn.as_control().Free();
        }
        std.debug.assert(app.list.NumChildren() == 0);

        var iter = app.data.iterator();
        while (iter.next()) |kv| {
            const datum = kv.value_ptr.*;
            const id = kv.key_ptr.*;
            const keep = if (filter_text) |text| keep: {
                const name_starts_with = std.mem.startsWith(u8, datum.name, text);
                const surname_starts_with = std.mem.startsWith(u8, datum.surname, text);
                break :keep name_starts_with or surname_starts_with;
            } else true;

            if (keep) {
                const name_str = try std.fmt.allocPrintZ(allocator, "{s}, {s}", .{
                    datum.surname,
                    datum.name,
                });
                const btn = try ui.Button.New(name_str);
                app.list.Append(btn.as_control(), .dont_stretch);
                btn.OnClicked(anyopaque, SelectError, on_item_clicked, @ptrFromInt(id));
                try app.list_buttons.append(btn);
            }
        }
    }
};

pub fn on_closing(_: *ui.Window, _: ?*App) !ui.Window.ClosingAction {
    ui.Quit();
    return .should_close;
}

const SelectError = ui.Error || App.SetSelectedError || error{};
pub fn on_item_clicked(_: *ui.Button, userdata: ?*anyopaque) SelectError!void {
    const id = @intFromPtr(userdata);
    try global_app.setSelected(id);
}

const FilterError = ui.Error || App.ListUpdateError;
pub fn on_filter_changed(entry: *ui.Entry, app_opt: ?*App) FilterError!void {
    const app = app_opt orelse return error.LibUINullUserdata;
    const text = std.mem.span(entry.Text());
    app.current_filter = text;
    try app.updateList(text);
}

const CreateError = ui.Error || App.AddDatumError || App.ListUpdateError;
pub fn on_create(_: *ui.Button, app_opt: ?*App) CreateError!void {
    const app = app_opt orelse return error.LibUINullUserdata;
    const name = std.mem.span(app.entry_name.Text());
    const surname = std.mem.span(app.entry_surname.Text());
    try app.addDatum(name, surname);
    try app.updateList(app.current_filter);
}

const UpdateError = ui.Error || App.ListUpdateError;
pub fn on_update(_: *ui.Button, app_opt: ?*App) UpdateError!void {
    const app = app_opt orelse return error.LibUINullUserdata;
    const name = std.mem.span(app.entry_name.Text());
    const surname = std.mem.span(app.entry_surname.Text());
    const index = app.selected_id orelse return;
    try app.setDatum(index, name, surname);
    try app.updateList(app.current_filter);
}

const DeleteError = ui.Error || App.ListUpdateError;
pub fn on_delete(_: *ui.Button, app_opt: ?*App) DeleteError!void {
    const app = app_opt orelse return error.LibUINullUserdata;
    const index = app.selected_id orelse return;
    app.deleteDatum(index);
    try app.updateList(app.current_filter);
}
