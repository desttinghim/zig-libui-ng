/// Container for forms. Each widgets gets a label on the left side and the actual control
/// on the right.
pub const Form = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }

    pub extern fn uiFormAppend(f: *Form, label: [*:0]const u8, c: *Control, stretchy: Stretchy) void;
    pub extern fn uiFormNumChildren(f: *Form) c_int;
    pub extern fn uiFormDelete(f: *Form, index: c_int) void;
    pub extern fn uiFormPadded(f: *Form) c_int;
    pub extern fn uiFormSetPadded(f: *Form, padded: c_int) void;
    pub extern fn uiNewForm() ?*Form;

    pub const Append = uiFormAppend;
    pub const NumChildren = uiFormNumChildren;
    pub const Delete = uiFormDelete;
    pub fn Padded(f: *Form) bool {
        return uiFormPadded(f) != 0;
    }
    pub fn SetPadded(f: *Form, padded: bool) void {
        uiFormSetPadded(f, @intFromBool(padded));
    }
    pub fn New() !*Form {
        return uiNewForm() orelse return error.InitForm;
    }
};

/// `Box` is a container control that will arrange it's children in a vertical or
/// horizontal line.
pub const Box = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }

    pub extern fn uiBoxAppend(b: *Box, child: *Control, stretchy: Stretchy) void;
    pub extern fn uiBoxNumChildren(b: *Box) c_int;
    pub extern fn uiBoxDelete(b: *Box, index: c_int) void;
    pub extern fn uiBoxPadded(b: *Box) c_int;
    pub extern fn uiBoxSetPadded(b: *Box, padded: c_int) void;
    pub extern fn uiNewHorizontalBox() ?*Box;
    pub extern fn uiNewVerticalBox() ?*Box;

    pub const Append = uiBoxAppend;
    pub const NumChildren = uiBoxNumChildren;
    pub const Delete = uiBoxDelete;

    pub fn Padded(b: *Box) bool {
        return uiBoxPadded(b) != 0;
    }

    pub fn SetPadded(b: *Box, padded: bool) void {
        uiBoxSetPadded(b, @intFromBool(padded));
    }

    pub const Orientation = enum {
        Vertical,
        Horizontal,
    };
    pub fn New(orientation: Orientation) !*Box {
        const new_box = switch (orientation) {
            .Vertical => uiNewVerticalBox(),
            .Horizontal => uiNewHorizontalBox(),
        };
        if (new_box == null) return error.InitBox;
        return new_box.?;
    }
};

/// The Grid container allows the developer to define a grid of a custom size and position
/// controls within it. Controls may span multiple cells of the grid. Useful for more
/// advanced layouts.
pub const Grid = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }

    pub const Position = struct {
        /// Placement as number of columns from the left. Integer in range of `[INT_MIN, INT_MAX]`.
        left: c_int = 0,
        /// Placement as number of rows from the top. Integer in range of `[INT_MIN, INT_MAX]`.
        top: c_int = 0,
    };

    pub const At = enum(c_int) {
        /// Place before control
        Leading = 0,
        /// Place above control
        Top = 1,
        /// Place behind control
        Trailing = 2,
        /// Place below control
        Bottom = 3,
    };

    pub const Align = enum(c_int) {
        Fill = 0,
        Start = 1,
        Center = 2,
        End = 3,
    };

    pub const Sizing = struct {
        /// Number of columns to span. Integer in range of `[0, INT_MAX]`.
        /// Defaults to 1.
        xspan: c_int = 1,
        /// Number of rows to span. Integer in range of `[0, INT_MAX]`.
        /// Defaults to 1.
        yspan: c_int = 1,
        /// `TRUE` to expand reserved area horizontally, `FALSE` otherwise.
        hexpand: bool = false,
        /// Horizontal alignment of the control within the reserved space.
        halign: Grid.Align = .Center,
        /// `TRUE` to expand reserved area vertically, `FALSE` otherwise.
        vexpand: bool = false,
        /// Vertical alignment of the control within the reserved space.
        valign: Grid.Align = .Center,
    };

    pub extern fn uiGridAppend(g: *Grid, c: ?*Control, left: c_int, top: c_int, xspan: c_int, yspan: c_int, hexpand: c_int, halign: Grid.Align, vexpand: c_int, valign: Grid.Align) void;
    pub extern fn uiGridInsertAt(g: *Grid, c: ?*Control, existing: *Control, at: Grid.At, xspan: c_int, yspan: c_int, hexpand: c_int, halign: Grid.Align, vexpand: c_int, valign: Grid.Align) void;
    pub extern fn uiGridPadded(g: *Grid) c_int;
    pub extern fn uiGridSetPadded(g: *Grid, padded: c_int) void;
    pub extern fn uiNewGrid() ?*Grid;

    pub const Append = uiGridAppend;
    pub const InsertAt = uiGridInsertAt;
    pub fn Padded(g: *Grid) bool {
        return uiGridPadded(g) != 0;
    }
    pub fn SetPadded(g: *Grid, padded: bool) void {
        uiGridSetPadded(g, @intFromBool(padded));
    }
    pub fn New() !*Grid {
        const new_grid = uiNewGrid();
        if (new_grid == null) return error.InitGrid;
        return new_grid.?;
    }
    pub fn append(g: *Grid, c: ?*Control, pos: Grid.Position, size: Grid.Sizing) void {
        g.Append(
            c,
            pos.left,
            pos.top,
            size.xspan,
            size.yspan,
            @intFromBool(size.hexpand),
            size.halign,
            @intFromBool(size.vexpand),
            size.valign,
        );
    }
    pub fn insert_at(g: *Grid, c: ?*Control, existing: ?*Control, at: Grid.At, size: Grid.Sizing) void {
        g.InsertAt(
            c,
            existing,
            at,
            size.xspan,
            size.yspan,
            @intFromBool(size.hexpand),
            size.halign,
            @intFromBool(size.vexpand),
            size.valign,
        );
    }
};

/// Group is container control that takes a single child that will be visually
/// separated from surrounding controls. `Group` is usually used along with another
/// container.
pub const Group = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }

    pub extern fn uiGroupTitle(g: *Group) [*:0]u8;
    pub extern fn uiGroupSetTitle(g: *Group, title: [*:0]const u8) void;
    pub extern fn uiGroupSetChild(g: *Group, c: *Control) void;
    pub extern fn uiGroupMargined(g: *Group) c_int;
    pub extern fn uiGroupSetMargined(g: *Group, margined: c_int) void;
    pub extern fn uiNewGroup(title: [*:0]const u8) ?*Group;

    pub const Title = uiGroupTitle;
    pub const SetTitle = uiGroupSetTitle;
    pub const SetChild = uiGroupSetChild;
    pub fn Margined(g: *Group) bool {
        return uiGroupMargined(g) != 0;
    }
    pub fn SetMargined(g: *Group, margined: bool) void {
        uiGroupSetMargined(g, margined);
    }
    pub fn New(title: [*:0]const u8) !*Group {
        return uiNewGroup(title) orelse error.InitGroup;
    }
};

/// Seperator is a control for visually separating controls.
pub const Separator = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }

    pub extern fn uiNewHorizontalSeparator() ?*Separator;
    pub extern fn uiNewVerticalSeparator() ?*Separator;

    pub const TypeEnum = enum {
        Horizontal,
        Vertical,
    };
    pub fn New(t: TypeEnum) !*Separator {
        return switch (t) {
            .Horizontal => uiNewHorizontalSeparator(),
            .Vertical => uiNewVerticalSeparator(),
        } orelse error.InitSeparator;
    }
};

/// Tab is a container control that switches between multiple pages using tabs.
pub const Tab = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }

    pub extern fn uiTabAppend(t: *Tab, name: [*:0]const u8, c: *Control) void;
    pub extern fn uiTabInsertAt(t: *Tab, name: [*:0]const u8, index: c_int, c: [*:0]Control) void;
    pub extern fn uiTabDelete(t: *Tab, index: c_int) void;
    pub extern fn uiTabNumPages(t: *Tab) c_int;
    pub extern fn uiTabMargined(t: *Tab, index: c_int) c_int;
    pub extern fn uiTabSetMargined(t: *Tab, index: c_int, margined: c_int) void;
    pub extern fn uiNewTab() ?*Tab;

    pub const Append = uiTabAppend;
    pub const InsertAt = uiTabInsertAt;
    pub const Delete = uiTabDelete;
    pub const NumPages = uiTabNumPages;

    pub fn Margined(t: *Tab, index: c_int) bool {
        return uiTabMargined(t, index) != 0;
    }
    pub fn SetMargined(t: *Tab, index: c_int, margined: bool) void {
        return uiTabSetMargined(t, index, @intFromBool(margined));
    }
    pub fn New() !*Tab {
        return uiNewTab() orelse error.InitTab;
    }
};

pub const Control = ui.Control;
pub const error_handler = ui.error_handler;
pub const ErrorContext = ui.ErrorContext;
pub const Stretchy = ui.Stretchy;

pub const ui = @import("ui.zig");
