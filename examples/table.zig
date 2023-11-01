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

    // Allocate a space on the stack to store a `extras.Table(TestStruct)`.
    var table: extras.Table(TestStruct) = undefined;

    // Initialize the `extras.Table(TestStruct)` and pass it `data` as the backing data.
    const data = [_]TestStruct{
        .{ .field_1 = 1, .field_2 = "hello", .field_3 = .{ .data = 0 }, .field_4 = .{ .data = 0 } },
        .{ .field_1 = 2, .field_2 = "world", .field_3 = .{ .data = 1 }, .field_4 = .{ .data = 50 } },
    };
    try table.init(.{ .const_slice = &data });

    // Defer deinitalization of `extras.Table(TestStruct)` to end of scope
    defer table.deinit();

    // Create a new `ui.Table` struct with the columns automatically populated
    const table_view = try table.NewViewDefaultColumns(.{});
    vbox.Append(table_view.as_control(), .stretch);

    ui.Main();
}

const TestStruct = struct {
    field_1: i32,
    field_2: [:0]const u8,
    field_3: extras.TableType.Checkbox,
    field_4: extras.TableType.Progress,
};
