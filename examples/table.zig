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

    main_window.as_control().Show();
    main_window.OnClosing(void, on_closing, null);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const data = [_]TestStruct{
        .{ .field_1 = 1 },
        .{ .field_1 = 2 },
    };

    const table = try Table(TestStruct).initAlloc(gpa.allocator(), .{ .const_slice = &data });
    defer table.deinitAlloc(gpa.allocator());

    const table_view = try table.NewView(.{});
    main_window.SetChild(table_view.as_control());

    ui.Main();
}

const TestStruct = struct {
    field_1: i32,
};

// Table code

pub fn Table(comptime T: type) type {
    const info = @typeInfo(T);
    const struct_info = switch (info) {
        .Struct => |s| s,
        else => @compileError("Table requires a struct type to be passed"),
    };
    const num_columns = struct_info.fields.len;
    //     for (info.Struct.fields) |field| {
    //     field.
    // }
    return struct {
        handler: ui.Table.Model.Handler = undefined,
        model: *ui.Table.Model = undefined,
        data: BackingData = undefined,

        // Public API
        pub const BackingDataOpt = union(enum) {
            new_array_list: std.mem.Allocator,
            array_list: *std.ArrayList(T),
            const_slice: []const T,
        };

        const BackingData = union(enum) {
            array_list: *std.ArrayList(T),
            const_slice: []const T,
        };

        pub fn initAlloc(allocator: std.mem.Allocator, data: BackingDataOpt) !*@This() {
            const self = try allocator.create(@This());
            errdefer allocator.destroy(self);

            try self.init(data);

            return self;
        }

        pub fn init(self: *@This(), data: BackingDataOpt) !void {
            self.handler = getHandler();

            self.model = try ui.Table.Model.New(&self.handler);
            errdefer ui.Table.Model.Free(self.model);

            self.data = switch (data) {
                .new_array_list => |alloc| new_list: {
                    const new = try alloc.create(std.ArrayList(T));
                    new.* = std.ArrayList(T).init(alloc);
                    break :new_list .{ .array_list = new };
                },
                .array_list => |ptr| .{ .array_list = ptr },
                .const_slice => |slice| .{ .const_slice = slice },
            };

            // return self;
        }

        pub fn deinit(self: *@This()) void {
            switch (self.data) {
                .array_list => |list| list.deinit(),
                .const_slice => {},
            }
            ui.Table.Model.Free(self.model);
        }

        pub fn deinitAlloc(self: *@This(), allocator: std.mem.Allocator) void {
            self.deinit();
            allocator.destroy(self);
        }

        pub const ViewParams = struct {
            // Indicates a column that defines a color for the row
            // If unspecified (or set to Default), a single default
            // background color will be used for all rows
            RowBackground: ColorModelColumn = .Default,

            pub const ColorModelColumn = enum(c_int) {
                Default = -1,
                _,
            };
        };
        pub fn NewView(self: *const @This(), params: ViewParams) !*ui.Table {
            var ui_params = ui.Table.Params{
                .Model = self.model,
                .RowBackgroundColorModelColumn = @intFromEnum(params.RowBackground),
            };
            var table = ui.Table.New(&ui_params);
            return table;
        }

        // Implementation - these functions are not meant to be called by the user - if you
        // find yourself doing that, please create an issue explaining why

        fn getHandler() ui.Table.Model.Handler {
            return .{
                .NumColumns = &numColumns,
                .ColumnType = &columnType,
                .NumRows = &numRows,
                .CellValue = &cellValue,
                .SetCellValue = &setCellValue,
            };
        }

        fn from_model_handler(handler: *ui.Table.Model.Handler) *@This() {
            return @fieldParentPtr(@This(), "handler", handler);
        }

        fn numColumns(handler: ?*ui.Table.Model.Handler, model: ?*ui.Table.Model) callconv(.C) c_int {
            _ = model;
            _ = handler;
            return @intCast(num_columns); // comptime number based on number of fields in T
        }

        fn columnType(handler: *ui.Table.Model.Handler, model: *ui.Table.Model, columni: c_int) callconv(.C) ui.Table.Value.Type {
            _ = model;
            _ = handler;
            _ = columni;
            return .String; // Always return string
            // const column: usize = @intCast(columni);
            // const self = from_model_handler(handler);
            // return self.column_def[column];
            // return switch (column) {
            //     inline 0..column => |field_index| switch (@typeInfo(struct_info.fields[field_index].type)) {
            //         .Int, .Float => .String,
            //         // .Pointer => ,
            //         else => @compileError("Table column must be an integer, a floating point value, or a string."),
            //     },
            //     else => @panic("Table columnType callback out of bounds!"),
            // };
        }

        fn numRows(handler: ?*ui.Table.Model.Handler, model: ?*ui.Table.Model) callconv(.C) c_int {
            _ = model;
            const self = from_model_handler(handler orelse return 0);
            const len = switch (self.data) {
                .array_list => |list| list.items.len,
                .const_slice => |slice| slice.len,
            };
            return @as(c_int, @intCast(len));
        }

        fn cellValue(handler: ?*ui.Table.Model.Handler, model: ?*ui.Table.Model, rowi: c_int, columni: c_int) callconv(.C) ?*ui.Table.Value {
            _ = model;
            const row = @as(usize, @intCast(rowi));
            const column = @as(usize, @intCast(columni));
            const self = from_model_handler(handler orelse @panic("null handler"));

            // const field_name = struct_info.fields[column].name;
            const data = switch (self.data) {
                .array_list => |list| list.items[row],
                .const_slice => |slice| slice[row],
            };
            switch (column) {
                inline 0...num_columns - 1 => |field_index| {
                    const field_name = struct_info.fields[field_index].name;
                    var buffer: [1048]u8 = undefined;
                    const string = std.fmt.bufPrintZ(&buffer, "{}", .{@field(data, field_name)}) catch @panic("Formatting column " ++ field_name);
                    return ui.Table.Value.New(.{ .String = string }) catch @panic("Unable to create new ui.Table.Value");
                },
                else => @panic(""),
            }

            // const index = row * self.column_def.len + column;
            // const value = self.array_list.items[index];
            // switch (self.column_def[column]) {
            //     .String => return ui.Table.Value.New(.{ .String = value.String.ptr }) catch @panic(""),
            //     .Int => return ui.Table.Value.New(.{ .Int = value.Int }) catch @panic(""),
            //     else => @panic("unimplemented"),
            // }
        }

        fn setCellValue(handler: ?*ui.Table.Model.Handler, model: ?*ui.Table.Model, rowi: c_int, columni: c_int, value_opt: ?*const ui.Table.Value) callconv(.C) void {
            const row = @as(usize, @intCast(rowi));
            const column = @as(usize, @intCast(columni));
            const self = from_model_handler(handler orelse return);

            // const index = row * self.column_def.len + column;
            const value = value_opt orelse return;

            const t = @as(ui.Table.Value.Type, value.GetType());
            const data = switch (self.data) {
                .array_list => |list| &list.items[row],
                .const_slice => @panic("Cannot write to const slice"),
            };

            switch (column) {
                inline 0...num_columns - 1 => |field_index| {
                    switch (t) {
                        .String => {
                            const string = std.mem.span(value.String());
                            @field(data, struct_info.fields[field_index].name) = std.fmt.parseInt(i32, string, 10) catch @panic("");
                            // var buffer: [1024]u8 = undefined;
                            // const new_string = std.fmt.bufPrint(&buffer, "", .{@field(data, field_name)}) catch @panic("");
                            model.?.RowChanged(@intCast(row));
                            // self.array_list.items[index].String = string;
                        },
                        else => @panic("unimplemented"),
                    }
                },
                else => @panic(""),
            }
        }
    };
}
