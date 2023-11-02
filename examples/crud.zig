//! A simple example of a CRUD (Create Read Update Delete) application using libui and the
//! Table comptime function from ui-extras.
const std = @import("std");
const ui = @import("ui");
const extras = @import("ui-extras");

pub fn on_closing(_: *ui.Window, _: ?*void) ui.Window.ClosingAction {
    ui.Quit();
    return .should_close;
}

pub fn on_click(_: *ui.Button, table: ?*extras.Table(Edit)) void {
    const name = table.?.allocator.?.dupeZ(u8, "Step") catch @panic("");
    const button_text = table.?.allocator.?.dupeZ(u8, "View") catch @panic("");
    table.?.data.array_list.append(.{ .name = name, .button_text = button_text }) catch @panic("");
    table.?.model.RowInserted(@intCast(table.?.data.array_list.items.len - 1));
}

pub fn on_table_button_clicked(_: *extras.Table(Edit), value: *Edit, column: usize, row: usize) void {
    std.log.debug("Button for column {}, row {}, clicked. Value is: {}", .{ column, row, value });
}

pub fn main() !void {
    // Initialize libui
    var init_data = ui.InitData{
        .options = .{ .Size = 0 },
    };
    ui.Init(&init_data) catch {
        std.debug.print("Error initializing LibUI: {s}\n", .{init_data.get_error()});
        init_data.free_error();
        return;
    };
    defer ui.Uninit();

    // Create a ui.Window
    const main_window = try ui.Window.New("Hello, World!", 320, 240, .hide_menubar);

    main_window.as_control().Show();
    main_window.OnClosing(void, on_closing, null);

    const vbox = try ui.Box.New(.Vertical);
    main_window.SetChild(vbox.as_control());

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const string_allocator = gpa.allocator();

    // Allocate a space on the stack to store a `extras.Table(TestStruct)`.
    var table: extras.Table(Edit) = undefined;

    // Initialize the `extras.Table(TestStruct)` and pass it an ArrayList
    var data = std.ArrayList(Edit).init(gpa.allocator());
    defer data.deinit();

    try table.init(.{ .array_list = &data }, string_allocator);
    defer table.deinit(); // Defer deinitalization of `extras.Table(TestStruct)` to end of scope
    table.button_callback = on_table_button_clicked;

    // Create a table view without using the default column generator
    const custom_table_view = try table.NewView(.{});
    custom_table_view.AppendColumn("Editable", .{ .Checkbox = .{
        .editable = .Always,
        .checkbox_column = 0,
    } });
    custom_table_view.AppendColumn("Name", .{ .Text = .{
        .editable = @enumFromInt(0),
        .text_column = 2,
    } });
    custom_table_view.AppendColumn("X", .{ .Text = .{
        .editable = @enumFromInt(0),
        .text_column = 3,
    } });
    custom_table_view.AppendColumn("Y", .{ .Text = .{
        .editable = @enumFromInt(0),
        .text_column = 4,
    } });
    custom_table_view.AppendColumn("Settle", .{ .Text = .{
        .editable = @enumFromInt(0),
        .text_column = 5,
    } });
    custom_table_view.AppendColumn("Expose", .{ .Text = .{
        .editable = @enumFromInt(0),
        .text_column = 6,
    } });
    custom_table_view.AppendColumn("Interstitial", .{ .Text = .{
        .editable = @enumFromInt(0),
        .text_column = 7,
    } });
    custom_table_view.AppendColumn("View", .{ .Button = .{
        .button_column = 1,
        .button_clickable = .Always,
    } });
    vbox.Append(custom_table_view.as_control(), .stretch);

    const button = try ui.Button.New("Add Row");
    button.OnClicked(extras.Table(Edit), on_click, &table);
    vbox.Append(button.as_control(), .dont_stretch);

    ui.Main();
}

const Edit = struct {
    editable: extras.TableType.Checkbox = .{ .data = 1 },
    button_text: [:0]const u8,
    name: [:0]const u8,
    x_pos: f64 = 0,
    y_pos: f64 = 0,
    settle_time: f64 = 20,
    expose_time: f64 = 0,
    interstitial_time: f64 = 0,
};

const Run = struct {
    name: [:0]const u8,
    x_pos: f64,
    y_pos: f64,
    settle_time: f64,
    expose_time: f64,
    interstitial_time: f64 = 0,
    progress: extras.TableType.Progress,
    color: extras.TableType.Color = .{ .r = 0, .g = 0, .b = 0, .a = 0 },
};
