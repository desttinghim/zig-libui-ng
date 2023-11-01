const std = @import("std");
const ui = @import("ui");
const extras = @import("ui-extras");

pub fn on_closing(_: *ui.Window, _: ?*void) ui.Window.ClosingAction {
    ui.Quit();
    return .should_close;
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
    var const_table: extras.Table(TestStruct) = undefined;
    var table: extras.Table(TestStruct) = undefined;

    // ----
    // Initialize the `extras.Table(TestStruct)` and pass it a const slice
    const const_data = [_]TestStruct{
        .{ .field_1 = 1, .field_2 = "hello", .field_3 = .{ .data = 0 }, .field_4 = .{ .data = 0 } },
        .{ .field_1 = 2, .field_2 = "world", .field_3 = .{ .data = 1 }, .field_4 = .{ .data = 50 }, .color = .{ .r = 1, .g = 0, .b = 0, .a = 1 } },
    };
    try const_table.init(.{ .const_slice = &const_data }, null);
    defer const_table.deinit(); // Defer deinitalization of `extras.Table(TestStruct)` to end of scope

    const const_table_view = try const_table.NewViewDefaultColumns(.{ .row_background = @enumFromInt(5) });
    vbox.Append(const_table_view.as_control(), .stretch);
    // ----

    // ----
    // Initialize the `extras.Table(TestStruct)` and pass it an ArrayList
    var data = std.ArrayList(TestStruct).init(gpa.allocator());
    defer data.deinit();

    const hello = try string_allocator.dupeZ(u8, "Hello");
    const world = try string_allocator.dupeZ(u8, "World");
    try data.appendSlice(&.{
        .{ .field_1 = 1, .field_2 = hello, .field_3 = .{ .data = 0 }, .field_4 = .{ .data = 0 } },
        .{ .field_1 = 2, .field_2 = world, .field_3 = .{ .data = 1 }, .field_4 = .{ .data = 50 } },
    });

    try table.init(.{ .array_list = &data }, string_allocator);
    defer table.deinit(); // Defer deinitalization of `extras.Table(TestStruct)` to end of scope

    // Create a new `ui.Table` struct with the columns automatically populated
    const table_view = try table.NewViewDefaultColumns(.{});
    vbox.Append(table_view.as_control(), .stretch);
    // ----

    // Create a table view without using the default column generator
    const custom_table_view = try table.NewView(.{});
    custom_table_view.AppendColumn("Field 1", .{ .Text = .{
        .text_column = 0,
        .editable = @enumFromInt(2),
    } });
    custom_table_view.AppendColumn("Field 2", .{ .Text = .{
        .text_column = 1,
        .editable = @enumFromInt(2),
    } });
    custom_table_view.AppendColumn("Field 3", .{ .Checkbox = .{
        .checkbox_column = 2,
        .editable = .Always,
    } });
    custom_table_view.AppendColumn("Field 4", .{ .ProgressBar = .{
        .progress_column = 3,
    } });
    custom_table_view.AppendColumn("Float", .{ .Text = .{
        .text_column = 4,
        .editable = .Always,
    } });
    vbox.Append(custom_table_view.as_control(), .stretch);

    ui.Main();
}

const TestStruct = struct {
    field_1: i32,
    field_2: [:0]const u8,
    field_3: extras.TableType.Checkbox,
    field_4: extras.TableType.Progress,
    float: f32 = 0.0,
    color: extras.TableType.Color = .{ .r = 0, .g = 0, .b = 0, .a = 0 },
};
