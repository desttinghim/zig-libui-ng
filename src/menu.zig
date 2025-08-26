/// MenuItem is a control for a single item within a `Menu`. Must be created using one of
/// the `Append` functions on `Menu`.
pub const MenuItem = opaque {
    pub extern fn uiMenuItemEnable(m: *MenuItem) void;
    pub extern fn uiMenuItemDisable(m: *MenuItem) void;
    pub extern fn uiMenuItemOnClicked(m: *MenuItem, f: ?*const fn (?*MenuItem, ?*Window, ?*anyopaque) callconv(.c) void, data: ?*anyopaque) void;
    pub extern fn uiMenuItemChecked(m: *MenuItem) c_int;
    pub extern fn uiMenuItemSetChecked(m: *MenuItem, checked: c_int) void;

    pub const Enable = uiMenuItemEnable;
    pub const Disable = uiMenuItemDisable;
    pub const Self = @This();
    pub fn OnClicked(self: *Self, comptime T: type, comptime E: type, comptime f: *const fn (*Self, *Window, ?*T) E!void, userdata: ?*T) void {
        const callback = struct {
            fn callback(self_opt: ?*Self, window_opt: ?*Window, t_opt: ?*anyopaque) callconv(.c) void {
                const err_ctx = ErrorContext{ .MenuItemOnClicked = self_opt };
                const s = self_opt orelse return error_handler(err_ctx, t_opt, error.LibUIPassedNullPointer);
                const w = window_opt orelse return error_handler(err_ctx, t_opt, error.LibUIPassedNullPointer);
                f(s, w, @as(?*T, @ptrCast(@alignCast(t_opt)))) catch |err| error_handler(err_ctx, t_opt, err);
            }
        }.callback;
        uiMenuItemOnClicked(self, callback, userdata);
    }
    pub fn Checked(m: *MenuItem) bool {
        return uiMenuItemChecked(m) != 0;
    }
    pub fn SetChecked(m: *MenuItem, checked: bool) void {
        return uiMenuItemSetChecked(m, @intFromBool(checked));
    }
};

/// Menu is a control that shows a drop down list of `MenuItem`s when clicked. There
/// can be multiple `Menu`s, each with their own name.
pub const Menu = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }

    pub extern fn uiMenuAppendItem(m: *Menu, name: [*:0]const u8) ?*MenuItem;
    pub extern fn uiMenuAppendCheckItem(m: *Menu, name: [*:0]const u8) ?*MenuItem;
    pub extern fn uiMenuAppendQuitItem(m: *Menu) ?*MenuItem;
    pub extern fn uiMenuAppendPreferencesItem(m: *Menu) ?*MenuItem;
    pub extern fn uiMenuAppendAboutItem(m: *Menu) ?*MenuItem;
    pub extern fn uiMenuAppendSeparator(m: *Menu) void;
    pub extern fn uiNewMenu(name: [*:0]const u8) ?*Menu;

    pub fn AppendItem(m: *Menu, name: [*:0]const u8) !*MenuItem {
        return uiMenuAppendItem(m, name) orelse error.InitMenuItem;
    }
    pub fn AppendCheckItem(m: *Menu, name: [*:0]const u8) !*MenuItem {
        return uiMenuAppendCheckItem(m, name) orelse error.InitMenuItem;
    }
    pub fn AppendQuitItem(m: *Menu) !*MenuItem {
        return uiMenuAppendQuitItem(m) orelse error.InitMenuItem;
    }
    pub fn AppendPreferencesItem(m: *Menu) !*MenuItem {
        return uiMenuAppendPreferencesItem(m) orelse error.InitMenuItem;
    }
    pub fn AppendAboutItem(m: *Menu) !*MenuItem {
        return uiMenuAppendAboutItem(m) orelse error.InitMenuItem;
    }
    pub const AppendSeparator = uiMenuAppendSeparator;
    pub fn New(name: [*:0]const u8) !*Menu {
        return uiNewMenu(name) orelse error.InitMenu;
    }
};

pub const Control = ui.Control;
pub const error_handler = ui.error_handler;
pub const ErrorContext = ui.ErrorContext;
pub const Window = ui.Window;

pub const ui = @import("ui.zig");
