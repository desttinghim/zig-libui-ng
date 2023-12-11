pub const TableType = opaque {
    pub const Checkbox = struct {
        data: c_int,
    };
    pub const Progress = struct {
        data: c_int,
    };
    pub const Color = ui.Table.Value.ColorData;
    pub const Image = struct {
        data: *Image,
    };
};

/// Comptime function for creating table handler from a struct. This is a convenience only,
/// see `ui.Table` for the raw libui types.
///
/// - T should be a struct.
/// - Each field in a struct will correspond to a `column` in the `ui.Table.Model`.
/// - Integers, floats, and strings are represented as `ui.Table.Value.String` types.
///
/// Note that a `column` in `ui.Table.Model` is _not_ the same as a visual column in a `ui.Table`
/// widget. See `ui.Table.Model` and `ui.Table.AppendColumn` for more details.
pub fn Table(comptime T: type) type {
    const info = @typeInfo(T);
    const struct_info = switch (info) {
        .Struct => |s| s,
        else => @compileError("Table requires a struct type to be passed"),
    };
    const num_columns = struct_info.fields.len;
    return struct {
        handler: ui.Table.Model.Handler = undefined,
        model: *ui.Table.Model = undefined,
        data: BackingData = undefined,
        allocator: ?std.mem.Allocator = null,
        button_callback: ?*const fn (*@This(), *T, usize, usize) void = null,

        // ---- Public API ----

        /// Used to passed the table data to init. The ArrayList or const slice is
        /// owned by the caller, but must live until the Table(T) struct is deinitialized.
        pub const BackingData = union(enum) {
            array_list: *std.ArrayList(T),
            const_slice: []const T,
        };

        /// Convenience function to allocate memory for the Table(T) struct, initialize it,
        /// and return the pointer. Use deinitAlloc() to free the memory.
        pub fn initAlloc(allocator: std.mem.Allocator, data: BackingData) !*@This() {
            const self = try allocator.create(@This());
            errdefer allocator.destroy(self);

            try self.init(data, allocator);

            return self;
        }

        /// Initializes a Table(T) struct in memory. Creates the libui Table vtable, allocates
        /// a libui table model, and stores the backing data for later use.
        pub fn init(self: *@This(), data: BackingData, allocator: ?std.mem.Allocator) !void {
            self.handler = getHandler();

            self.model = try ui.Table.Model.New(&self.handler);
            errdefer ui.Table.Model.Free(self.model);

            self.data = data;

            self.allocator = allocator;

            self.button_callback = null;
        }

        /// Calls libui function to free the table model. Does not free backing data.
        pub fn deinit(self: *@This()) void {
            ui.Table.Model.Free(self.model);

            switch (self.data) {
                .const_slice => {}, // nothing to do
                .array_list => |list| {
                    const allocator = self.allocator orelse return;
                    for (list.items) |data| {
                        inline for (0..num_columns) |column| {
                            const field = struct_info.fields[column];
                            switch (field.type) {
                                [:0]const u8 => {
                                    allocator.free(@field(data, field.name));
                                },
                                else => {},
                            }
                        }
                    }
                },
            }
        }

        /// Calls libui function to free the table model and frees allocated memory.
        /// Does not free backing data.
        pub fn deinitAlloc(self: *@This(), allocator: std.mem.Allocator) void {
            self.deinit();
            allocator.destroy(self);
        }

        /// A parameters struct for calling NewView.
        pub const ViewParams = struct {
            // Indicates a column that defines a color for the row
            // If unspecified (or set to Default), a single default
            // background color will be used for all rows
            row_background: ColorModelColumn = .Default,

            pub const ColorModelColumn = enum(c_int) {
                /// All rows will use a default color for their background
                Default = -1,
                _,
            };
        };

        /// Creates a new `ui.Table` widget with `Table(T)` as the model.
        /// The table is owned by the caller. To automatically populate columns
        /// based on the struct `T`, use `NewViewDefaultColumns()`.
        pub fn NewView(self: *const @This(), params: ViewParams) !*ui.Table {
            var ui_params = ui.Table.Params{
                .Model = self.model,
                .RowBackgroundColorModelColumn = @intFromEnum(params.row_background),
            };
            const table = try ui.Table.New(&ui_params);
            return table;
        }

        /// Creates a new `ui.Table` widget and automatically populates the columns based
        /// on the struct `T`. The table is owned by the caller.
        /// For more control over the resulting columns, use `NewView()`.
        pub fn NewViewDefaultColumns(self: *const @This(), params: ViewParams) !*ui.Table {
            var table = try self.NewView(params);
            const editable: ui.Table.ColumnParameters.Editable = switch (self.data) {
                .const_slice => .Never,
                .array_list => .Always,
            };
            inline for (0..num_columns) |column| {
                const field = struct_info.fields[column];
                const name = std.fmt.comptimePrint("{s}", .{field.name});
                switch (field.type) {
                    TableType.Checkbox => {
                        table.AppendColumn(name, .{ .Checkbox = .{
                            .checkbox_column = column,
                            .editable = editable,
                        } });
                    },
                    TableType.Progress => {
                        table.AppendColumn(name, .{ .ProgressBar = .{
                            .progress_column = column,
                        } });
                    },
                    TableType.Image => {
                        table.AppendColumn(name, .{ .Image = .{
                            .image_column = column,
                        } });
                    },
                    TableType.Color => {
                        switch (params.row_background) {
                            .Default => {},
                            else => |color_column| {
                                std.debug.assert(@as(usize, @intCast(@intFromEnum(color_column))) == column);
                            },
                        }
                    },
                    else => {
                        table.AppendColumn(name, .{ .Text = .{
                            .text_column = column,
                            .editable = editable,
                            .text_params = null,
                        } });
                    },
                }
            }
            return table;
        }

        // Implementation - these functions are not meant to be called by the user - if you
        // find yourself doing that, please create an issue explaining why

        /// Internal convenience function for `Table(T)`.
        /// Creates the `ui.Table.Model.Handler` vtable struct by getting a reference
        /// to all of the callback functions.
        fn getHandler() ui.Table.Model.Handler {
            return .{
                .NumColumns = &numColumns,
                .ColumnType = &columnType,
                .NumRows = &numRows,
                .CellValue = &cellValue,
                .SetCellValue = &setCellValue,
            };
        }

        /// Internal convenience function for `Table(T)`.
        /// Gets a pointer to `Table(T)` from a pointer to a `ui.Table.Model`.
        fn from_model_handler(handler: *ui.Table.Model.Handler) *@This() {
            return @fieldParentPtr(@This(), "handler", handler);
        }

        /// Implementation of `numColumns` for `ui.Table.Model.Handler`. Returns the number
        /// of fields in struct `T`.
        fn numColumns(_: ?*ui.Table.Model.Handler, _: ?*ui.Table.Model) callconv(.C) c_int {
            return @intCast(num_columns); // comptime number based on number of fields in T
        }

        /// Implementation of `columnType` for `ui.Table.Model.Handler`.
        /// - `ui.Table.Value.Type.Int` is used for checkboxes and progress bars - can also be referenced by other columns to check editability
        /// - `ui.Table.Value.Type.Color` is used for setting the background color of rows
        /// - `ui.Table.Value.Type.Image` is used for displaying images
        /// - `ui.Table.Value.Type.Text`  is used for strings. For user editable integers and floats, this is used to allow editing.
        fn columnType(handler: *ui.Table.Model.Handler, _: *ui.Table.Model, columni: c_int) callconv(.C) ui.Table.Value.Type {
            _ = handler;

            const column = @as(usize, @intCast(columni));

            switch (column) {
                inline 0...num_columns - 1 => |field_index| {
                    const field = struct_info.fields[field_index];
                    return switch (field.type) {
                        TableType.Checkbox, TableType.Progress => .Int,
                        TableType.Color => .Color,
                        TableType.Image => .Image,
                        else => .String,
                    };
                },
                else => @panic("columnType column parameter out of bounds"),
            }
        }

        /// Implementation of `numRows` for `ui.Table.Model.Handler`.
        /// If an array list is used for the backing data, it returns `array_list.items.len`.
        /// If a const slice is used for the backing data, it return `slice.len`.
        fn numRows(handler: ?*ui.Table.Model.Handler, _: ?*ui.Table.Model) callconv(.C) c_int {
            const self = from_model_handler(handler orelse return 0);
            const len = switch (self.data) {
                .array_list => |list| list.items.len,
                .const_slice => |slice| slice.len,
            };
            return @as(c_int, @intCast(len));
        }

        /// Implementation of `cellValue` for `ui.Table.Model.Handler`.
        /// The value returned is based on the type of the field in struct `T`.
        fn cellValue(handler: ?*ui.Table.Model.Handler, _: ?*ui.Table.Model, rowi: c_int, columni: c_int) callconv(.C) ?*ui.Table.Value {
            const row = @as(usize, @intCast(rowi));
            const column = @as(usize, @intCast(columni));
            const self = from_model_handler(handler orelse @panic("null model"));

            const slice = switch (self.data) {
                .array_list => |list| list.items,
                .const_slice => |slice| slice,
            };
            if (slice.len < row) @panic("cellValue row parameter out of bounds");
            const data = &slice[row];

            var value_param: ?ui.Table.Value.TypeParameters = null;
            switch (column) {
                inline 0...num_columns - 1 => |field_index| {
                    const field = struct_info.fields[field_index];

                    switch (field.type) {
                        TableType.Checkbox, TableType.Progress => {
                            value_param = .{ .Int = @field(data, field.name).data };
                        },
                        TableType.Color => {
                            value_param = .{ .Color = @field(data, field.name) };
                        },
                        TableType.Image => {
                            @compileError("TableType.Image is unimplemented");
                        },
                        [:0]const u8, []const u8 => {
                            const string = @field(data, field.name);
                            value_param = .{ .String = @ptrCast(string) };
                        },
                        else => |t| {
                            var buffer: [1048]u8 = undefined;
                            const value = @field(data, field.name);
                            // TODO: allow user to configure float precision
                            // TODO: allow user to configure int base
                            const format_string = if (@typeInfo(t) == .Float) "{d:.2}" else "{any}";
                            const string = std.fmt.bufPrintZ(&buffer, format_string, .{value}) catch @panic("Formatting column " ++ field.name);
                            value_param = .{ .String = string };
                        },
                    }
                },
                else => @panic("cellValue column parameter out of bounds"),
            }

            const value = value_param orelse @panic("Value Param never set in cellValue. This is a bug in ziglibui");

            return ui.Table.Value.New(value) catch @panic("cellValue unable to call ui.Table.Value.New()");
        }

        fn setCellValue(handler: ?*ui.Table.Model.Handler, _: ?*ui.Table.Model, rowi: c_int, columni: c_int, value_opt: ?*const ui.Table.Value) callconv(.C) void {
            const row = @as(usize, @intCast(rowi));
            const column = @as(usize, @intCast(columni));
            const self = from_model_handler(handler orelse return);

            const data = switch (self.data) {
                .array_list => |list| item: {
                    if (list.items.len < row) {
                        @panic("setCellValue row out of list bounds");
                    }
                    break :item &list.items[row];
                },
                .const_slice => @panic("setCellValue called Table(T) with const slice backing, which is not allowed. Use an ArrayList instead."),
            };

            const value = value_opt orelse {
                if (self.button_callback) |button_callback| {
                    button_callback(self, data, column, row);
                } else {
                    std.log.debug("setCellValue called with null value on column {}, row {}", .{ column, row });
                }
                return;
            };

            const value_t = @as(ui.Table.Value.Type, value.GetType());

            switch (column) {
                inline 0...num_columns - 1 => |field_index| {
                    const field = struct_info.fields[field_index];
                    const previous_value = @field(data, field.name);
                    switch (field.type) {
                        TableType.Checkbox, TableType.Progress => {
                            std.debug.assert(value_t == .Int);
                            @field(data, field.name).data = value.Int();
                        },
                        TableType.Color => {
                            std.debug.assert(value_t == .Color);
                            @field(data, field.name) = value.Color();
                            // @compileError("TableType.Color is unimplemented");
                        },
                        TableType.Image => {
                            std.debug.assert(value_t == .Image);
                            @compileError("TableType.Image is unimplemented");
                        },
                        [:0]const u8 => {
                            std.debug.assert(value_t == .String);
                            const string = std.mem.span(value.String());
                            if (self.allocator) |alloc| {
                                alloc.free(@field(data, field.name)); // Free previous value
                                @field(data, field.name) = alloc.dupeZ(u8, string) catch @panic("setCellValue error running dupeZ on string");
                            } else {
                                std.log.info("No table allocator, could not store new value of string: {s}", .{string});
                            }
                        },
                        else => |t| {
                            if (@typeInfo(t) == .Int) {
                                std.debug.assert(value_t == .String);
                                const string = std.mem.span(value.String());
                                // TODO: allow API user to define base
                                const int_value = std.fmt.parseInt(t, string, 10) catch |e| switch (e) {
                                    error.Overflow => previous_value,
                                    error.InvalidCharacter => previous_value,
                                };
                                @field(data, field.name) = int_value;
                            } else if (@typeInfo(t) == .Float) {
                                std.debug.assert(value_t == .String);
                                const string = std.mem.span(value.String());
                                const float_value = std.fmt.parseFloat(t, string) catch |e| switch (e) {
                                    error.InvalidCharacter => previous_value,
                                };
                                @field(data, field.name) = float_value;
                            } else {
                                @panic("Unimplemented type");
                            }
                        },
                    }
                },
                else => @panic(""),
            }
        }
    };
}

const ui = @import("ui");
const std = @import("std");
