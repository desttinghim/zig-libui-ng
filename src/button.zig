/// `Button` is a clickable control that can run a callback when clicked.
pub const Button = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }

    pub extern fn uiButtonText(b: *Button) [*:0]const u8;
    pub extern fn uiButtonSetText(b: *Button, text: [*:0]const u8) void;
    pub extern fn uiButtonOnClicked(b: *Button, f: ?*const fn (*Button, ?*anyopaque) callconv(.c) void, data: ?*anyopaque) void;
    pub extern fn uiNewButton(text: [*:0]const u8) ?*Button;

    pub const Text = uiButtonText;
    pub const SetText = uiButtonSetText;

    pub fn OnClicked(self: *Self, comptime T: type, comptime E: type, comptime f: *const fn (*Self, ?*T) E!void, userdata: ?*T) void {
        const callback = struct {
            fn callback(button_opt: ?*Self, t_opt: ?*anyopaque) callconv(.c) void {
                const err_ctx = ErrorContext{ .ButtonOnClicked = button_opt };
                const b = button_opt orelse return error_handler(err_ctx, t_opt, error.LibUIPassedNullPointer);
                f(b, @as(?*T, @ptrCast(@alignCast(t_opt)))) catch |err| error_handler(err_ctx, t_opt, err);
            }
        }.callback;
        uiButtonOnClicked(self, callback, userdata);
    }

    pub fn New(text: [*:0]const u8) !*Button {
        const new_button = uiNewButton(text);
        if (new_button == null) return error.InitButton;
        return new_button.?;
    }
};

/// Allows the user to select a color.
pub const ColorButton = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }

    pub extern fn uiColorButtonColor(b: *ColorButton, r: *f64, g: *f64, bl: *f64, a: *f64) void;
    pub extern fn uiColorButtonSetColor(b: *ColorButton, r: f64, g: f64, bl: f64, a: f64) void;
    pub extern fn uiColorButtonOnChanged(b: *ColorButton, f: ?*const fn (?*ColorButton, ?*anyopaque) callconv(.c) void, data: ?*anyopaque) void;
    pub extern fn uiNewColorButton() ?*ColorButton;

    pub const ColorValue = struct {
        red: f64,
        green: f64,
        blue: f64,
        alpha: f64,
    };

    pub fn Color(cb: *const ColorButton) ColorValue {
        const color_value: ColorValue = undefined;
        uiColorButtonColor(
            cb,
            color_value.red,
            color_value.green,
            color_value.blue,
            color_value.alpha,
        );
        return color_value;
    }
    pub fn SetColor(cb: *const ColorButton, color_value: ColorValue) void {
        uiColorButtonSetColor(
            cb,
            color_value.red,
            color_value.green,
            color_value.alpha,
        );
    }
    pub fn OnChanged(self: *Self, comptime T: type, comptime E: type, f: *const fn (*Self, ?*T) E!void, userdata: ?*T) void {
        const callback = struct {
            fn callback(self_opt: ?*Self, t_opt: ?*anyopaque) callconv(.c) void {
                const err_ctx = ErrorContext{ .ColorButtonOnChanged = self_opt };
                const s = self_opt orelse return error_handler(err_ctx, t_opt, error.LibUIPassedNullPointer);
                f(s, @as(?*T, @ptrCast(@alignCast(t_opt)))) catch |err| error_handler(err_ctx, t_opt, err);
            }
        }.callback;
        uiColorButtonOnChanged(self, callback, userdata);
    }
    pub fn New() !*ColorButton {
        return uiNewColorButton() orelse error.InitColorButton;
    }
};

/// FontButton is a control that displays a font select dialog when it is clicked.
pub const FontButton = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }

    pub extern fn uiFontButtonFont(b: *FontButton, desc: *FontDescriptor) void;
    pub extern fn uiFontButtonOnChanged(b: *FontButton, comptime f: ?*const fn (?*FontButton, ?*anyopaque) callconv(.c) void, data: ?*anyopaque) void;
    pub extern fn uiNewFontButton() ?*FontButton;
    pub extern fn uiFreeFontButtonFont(desc: *FontDescriptor) void;

    pub const Font = uiFontButtonFont;
    pub fn OnChanged(self: *Self, comptime T: type, comptime E: type, comptime f: *const fn (*Self, ?*T) E!void, userdata: ?*T) void {
        const callback = struct {
            fn callback(self_opt: ?*Self, t_opt: ?*anyopaque) callconv(.c) void {
                const err_ctx = ErrorContext{ .FontButtonOnChanged = self_opt };
                const s = self_opt orelse return error_handler(err_ctx, t_opt, error.LibUIPassedNullPointer);
                f(s, @as(?*T, @ptrCast(@alignCast(t_opt)))) catch |err| error_handler(err_ctx, t_opt, err);
            }
        }.callback;
        uiFontButtonOnChanged(self, callback, userdata);
    }
    pub fn New() !*FontButton {
        return uiNewFontButton() orelse error.InitFontButton;
    }
    pub const FreeFont = uiFreeFontButtonFont;
};

const Control = ui.Control;
const ErrorContext = ui.ErrorContext;
const error_handler = ui.error_handler;
const FontDescriptor = ui.FontDescriptor;

const ui = @import("ui.zig");
