/// The Image struct contains an image to be used as a TableValue. Image is not derived
/// from Control and may not be added to the Control layout tree.
pub const Image = opaque {
    pub extern fn uiNewImage(width: f64, height: f64) ?*ui.Image;
    pub extern fn uiFreeImage(i: *ui.Image) void;
    pub extern fn uiImageAppend(i: *ui.Image, pixels: ?*anyopaque, pixelWidth: c_int, pixelHeight: c_int, byteStride: c_int) void;

    pub const Append = uiImageAppend;
    pub fn New() !*ui.Image {
        return uiNewImage() orelse return error.InitImage;
    }
    pub const Free = uiFreeImage;
};

/// The Table control is an advanced control that allows viewing and editing data in a
/// tabular format.
pub const Table = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }
    pub const Value = opaque {
        pub extern fn uiFreeTableValue(v: *Table.Value) void;
        pub extern fn uiTableValueGetType(v: *const Table.Value) Table.Value.Type;
        pub extern fn uiNewTableValueString(str: [*:0]const u8) ?*Table.Value;
        pub extern fn uiTableValueString(v: *const Table.Value) [*:0]const u8;
        pub extern fn uiNewTableValueImage(img: *ui.Image) ?*Table.Value;
        pub extern fn uiTableValueImage(v: *const Table.Value) ?*ui.Image;
        pub extern fn uiNewTableValueInt(i: c_int) ?*Table.Value;
        pub extern fn uiTableValueInt(v: *const Table.Value) c_int;
        pub extern fn uiNewTableValueColor(r: f64, g: f64, b: f64, a: f64) ?*Table.Value;
        pub extern fn uiTableValueColor(v: *const Table.Value, r: *f64, g: *f64, b: *f64, a: *f64) void;

        pub const Type = enum(c_int) {
            String = 0,
            Image = 1,
            Int = 2,
            Color = 3,
        };
        pub const SortIndicator = enum(c_int) {
            None = 0,
            Ascending = 1,
            Descending = 2,
        };
        pub const GetType = uiTableValueGetType;

        pub const ColorData = struct {
            r: f64,
            g: f64,
            b: f64,
            a: f64,
        };
        pub const TypeParameters = union(Type) {
            String: [*:0]const u8,
            Image: *ui.Image,
            Int: c_int,
            Color: ColorData,
        };
        pub fn New(t: TypeParameters) !*Value {
            return switch (t) {
                .String => |string| uiNewTableValueString(string),
                .Image => |image| uiNewTableValueImage(image),
                .Int => |int| uiNewTableValueInt(int),
                .Color => |color| uiNewTableValueColor(color.r, color.g, color.b, color.a),
            } orelse error.InitTableValue;
        }
        pub const String = uiTableValueString;
        pub const Image = uiTableValueImage;
        pub const Int = uiTableValueInt;
        pub fn Color(v: *const Table.Value) ColorData {
            var color: ColorData = undefined;
            v.uiTableValueColor(&color.r, &color.g, &color.b, &color.a);
            return color;
        }
    };
    pub const Model = opaque {
        pub const Handler = extern struct {
            NumColumns: *const fn (*Handler, *Model) callconv(.c) c_int,
            ColumnType: *const fn (*Handler, *Model, c_int) callconv(.c) Value.Type,
            NumRows: *const fn (*Handler, *Model) callconv(.c) c_int,
            CellValue: *const fn (*Handler, *Model, c_int, c_int) callconv(.c) ?*Value,
            SetCellValue: *const fn (*Handler, *Model, c_int, c_int, ?*const Value) callconv(.c) void,
        };

        pub extern fn uiNewTableModel(mh: *Table.Model.Handler) ?*Table.Model;
        pub extern fn uiFreeTableModel(m: *Table.Model) void;
        pub extern fn uiTableModelRowInserted(m: ?*Table.Model, newIndex: c_int) void;
        pub extern fn uiTableModelRowChanged(m: ?*Table.Model, index: c_int) void;
        pub extern fn uiTableModelRowDeleted(m: ?*Table.Model, oldIndex: c_int) void;

        pub fn New(mh: *Handler) !*Model {
            return uiNewTableModel(mh) orelse error.InitModel;
        }
        pub const Free = uiFreeTableModel;
        pub const RowInserted = uiTableModelRowInserted;
        pub const RowChanged = uiTableModelRowChanged;
        pub const RowDeleted = uiTableModelRowDeleted;
    };
    pub const TextColumnOptionalParams = extern struct {
        ColorModelColumn: c_int,
    };
    pub const ColumnParameters = union(enum) {
        Text: struct {
            text_column: c_int,
            editable: Editable,
            text_params: ?*TextColumnOptionalParams = null,
        },
        Image: struct {
            image_column: c_int,
        },
        ImageText: struct {
            image_column: c_int,
            text_column: c_int,
            editable: Editable,
            text_params: ?*TextColumnOptionalParams = null,
        },
        Checkbox: struct {
            checkbox_column: c_int,
            editable: Editable,
        },
        CheckboxText: struct {
            checkbox_column: c_int,
            checkbox_editable: Editable,
            text_column: c_int,
            text_editable: Editable,
            text_params: ?*TextColumnOptionalParams = null,
        },
        ProgressBar: struct {
            progress_column: c_int,
        },
        Button: struct {
            button_column: c_int,
            button_clickable: Editable,
        },

        pub const Editable = enum(c_int) {
            Never = -1,
            Always = -2,
            _,

            pub fn column(col: u31) Editable {
                return @enumFromInt(col);
            }
        };
    };
    pub fn AppendColumn(t: *Table, name: [*:0]const u8, params: ColumnParameters) void {
        switch (params) {
            .Text => |p| uiTableAppendTextColumn(t, name, p.text_column, @intFromEnum(p.editable), p.text_params),
            .Image => |p| uiTableAppendImageColumn(t, name, p.image_column),
            .ImageText => |p| uiTableAppendImageTextColumn(t, name, p.image_column, p.text_column, @intFromEnum(p.editable), p.text_params),
            .Checkbox => |p| uiTableAppendCheckboxColumn(t, name, p.checkbox_column, @intFromEnum(p.editable)),
            .CheckboxText => |p| uiTableAppendCheckboxTextColumn(t, name, p.checkbox_column, @intFromEnum(p.checkbox_editable), p.text_column, @intFromEnum(p.text_editable), p.text_params),
            .ProgressBar => |p| uiTableAppendProgressBarColumn(t, name, p.progress_column),
            .Button => |p| uiTableAppendButtonColumn(t, name, p.button_column, @intFromEnum(p.button_clickable)),
        }
    }
    pub fn HeaderVisible(t: *Table) bool {
        return uiTableHeaderVisible(t) != 0;
    }
    pub fn HeaderSetVisible(t: *Table, visible: bool) void {
        uiTableHeaderSetVisible(t, @intFromBool(visible));
    }
    pub const Params = extern struct {
        Model: *Model,
        RowBackgroundColorModelColumn: c_int,
    };
    pub fn New(params: *Params) !*Table {
        return uiNewTable(params) orelse error.InitTable;
    }

    pub extern fn uiTableAppendTextColumn(t: *Table, name: [*:0]const u8, textModelColumn: c_int, textEditableModelColumn: c_int, textParams: ?*Table.TextColumnOptionalParams) void;
    pub extern fn uiTableAppendImageColumn(t: *Table, name: [*:0]const u8, imageModelColumn: c_int) void;
    pub extern fn uiTableAppendImageTextColumn(t: *Table, name: [*:0]const u8, imageModelColumn: c_int, textModelColumn: c_int, textEditableModelColumn: c_int, textParams: ?*Table.TextColumnOptionalParams) void;
    pub extern fn uiTableAppendCheckboxColumn(t: *Table, name: [*:0]const u8, checkboxModelColumn: c_int, checkboxEditableModelColumn: c_int) void;
    pub extern fn uiTableAppendCheckboxTextColumn(t: *Table, name: [*:0]const u8, checkboxModelColumn: c_int, checkboxEditableModelColumn: c_int, textModelColumn: c_int, textEditableModelColumn: c_int, textParams: ?*Table.TextColumnOptionalParams) void;
    pub extern fn uiTableAppendProgressBarColumn(t: *Table, name: [*:0]const u8, progressModelColumn: c_int) void;
    pub extern fn uiTableAppendButtonColumn(t: *Table, name: [*:0]const u8, buttonModelColumn: c_int, buttonClickableModelColumn: c_int) void;
    pub extern fn uiTableHeaderVisible(t: *Table) c_int;
    pub extern fn uiTableHeaderSetVisible(t: *Table, visible: c_int) void;
    pub extern fn uiNewTable(params: *Table.Params) ?*Table;
    pub extern fn uiTableOnRowClicked(t: *Table, f: ?*const fn (?*Table, c_int, ?*anyopaque) callconv(.c) void, data: ?*anyopaque) void;
    pub extern fn uiTableOnRowDoubleClicked(t: *Table, f: ?*const fn (?*Table, c_int, ?*anyopaque) callconv(.c) void, data: ?*anyopaque) void;
    pub extern fn uiTableHeaderSetSortIndicator(t: *Table, column: c_int, indicator: Table.Value.SortIndicator) void;
    pub extern fn uiTableHeaderSortIndicator(t: *Table, column: c_int) Table.Value.SortIndicator;
    pub extern fn uiTableHeaderOnClicked(t: *Table, f: ?*const fn (?*Table, c_int, ?*anyopaque) callconv(.c) void, data: ?*anyopaque) void;
    pub extern fn uiTableColumnWidth(t: *Table, column: c_int) c_int;
    pub extern fn uiTableColumnSetWidth(t: *Table, column: c_int, width: c_int) void;

    pub fn OnRowClicked(self: *Self, comptime T: type, comptime E: type, comptime f: *const fn (*Self, ?*T) E!void, userdata: ?*T) void {
        const callback = struct {
            fn callback(self_opt: ?*Self, t_opt: ?*anyopaque) callconv(.c) void {
                const err_ctx = ErrorContext{ .TableOnRowClicked = self_opt };
                const s = self_opt orelse return error_handler(err_ctx, t_opt, error.LibUIPassedNullPointer);
                f(s, @as(?*T, @ptrCast(@alignCast(t_opt)))) catch |err| error_handler(err_ctx, t_opt, err);
            }
        }.callback;
        uiTableOnRowClicked(self, callback, userdata);
    }
    pub fn OnRowDoubleClicked(self: *Self, comptime T: type, comptime E: type, f: *const fn (*Self, ?*T) E!void, userdata: ?*T) void {
        const callback = struct {
            fn callback(self_opt: ?*Self, t_opt: ?*anyopaque) callconv(.c) void {
                const err_ctx = ErrorContext{ .TableOnRowDoubleClicked = self_opt };
                const s = self_opt orelse return error_handler(err_ctx, t_opt, error.LibUIPassedNullPointer);
                f(s, @as(?*T, @ptrCast(@alignCast(t_opt)))) catch |err| error_handler(err_ctx, t_opt, err);
            }
        }.callback;
        uiTableOnRowDoubleClicked(self, callback, userdata);
    }
    pub const HeaderSetSortIndicator = uiTableHeaderSetSortIndicator;
    pub const HeaderSortIndicator = uiTableHeaderSortIndicator;
    pub const HeaderOnClicked = uiTableHeaderOnClicked;
    pub const ColumnWidth = uiTableColumnWidth;
    pub const ColumnSetWidth = uiTableColumnSetWidth;

    pub const SelectionMode = enum(c_int) {
        None = 0,
        ZeroOrOne = 1,
        One = 2,
        ZeroOrMany = 3,
    };

    pub extern fn uiTableGetSelectionMode(t: *Table) Table.SelectionMode;
    pub extern fn uiTableSetSelectionMode(t: *Table, mode: Table.SelectionMode) void;
    pub extern fn uiTableOnSelectionChanged(t: *Table, f: ?*const fn (?*Table, ?*anyopaque) callconv(.c) void, data: ?*anyopaque) void;

    pub extern fn uiTableGetSelection(t: *Table) ?*Table.Selection;
    pub extern fn uiTableSetSelection(t: *Table, sel: *Table.Selection) void;
    pub extern fn uiFreeTableSelection(s: *Table.Selection) void;

    pub const GetSelectionMode = uiTableGetSelectionMode;
    pub const SetSelectionMode = uiTableSetSelectionMode;
    pub fn OnSelectionChanged(self: *Self, comptime T: type, comptime E: type, comptime f: *const fn (*Self, ?*T) E!void, userdata: ?*T) void {
        const callback = struct {
            fn callback(self_opt: ?*Self, t_opt: ?*anyopaque) callconv(.c) void {
                const err_ctx = ErrorContext{ .TableOnSelectionChanged = self_opt };
                const s = self_opt orelse return error_handler(err_ctx, t_opt, error.LibUIPassedNullPointer);
                f(s, @as(?*T, @ptrCast(@alignCast(t_opt)))) catch |err| error_handler(err_ctx, t_opt, err);
            }
        }.callback;
        uiTableOnSelectionChanged(self, callback, userdata);
    }

    pub const Selection = extern struct {
        NumRows: c_int,
        Rows: [*]c_int,
    };

    pub const GetSelection = uiTableGetSelection;
    pub const SetSelection = uiTableSetSelection;
};

pub const Control = ui.Control;
pub const error_handler = ui.error_handler;
pub const ErrorContext = ui.ErrorContext;

pub const ui = @import("ui.zig");
