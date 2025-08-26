/// DateTimePicker is a control that allows the user to select a date and/or time.
///
/// All functions operate on `struct tm` as defined in `<time.h>`.
///
/// All functions assume local time and do NOT perform any time zone conversions.
///
/// @warning The `struct_tm` members `week_day` and `year_day` are undefined.
/// @warning The `struct_tm` member `is_dst` is ignored on windows and should be set to `-1`.
///
/// @todo for Time: define what values are returned when a part is missing
pub const DateTimePicker = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }

    pub extern fn uiDateTimePickerTime(d: *DateTimePicker, time: *struct_tm) void;
    pub extern fn uiDateTimePickerSetTime(d: *DateTimePicker, time: *const struct_tm) void;
    pub extern fn uiDateTimePickerOnChanged(d: *DateTimePicker, f: ?*const fn (?*DateTimePicker, ?*anyopaque) callconv(.c) void, data: ?*anyopaque) void;
    pub extern fn uiNewDateTimePicker() ?*DateTimePicker;
    pub extern fn uiNewDatePicker() ?*DateTimePicker;
    pub extern fn uiNewTimePicker() ?*DateTimePicker;

    /// Based on `struct tm` from BSD standard `time.h`
    /// Fields have been renamed to make them clearer.
    pub const struct_tm = extern struct {
        /// Renamed from `tm_sec`.
        /// Seconds after the minute - [0, 61] (until C99), [0, 60] (since C99)
        second: c_int = 0,
        /// Renamed from `tm_min`.
        /// Minutes after the hour - [0, 59]
        minute: c_int = 0,
        /// Renamed from `tm_hour`.
        /// Hours since midnight - [0, 23]
        hour: c_int = 0,
        /// Renamed from `tm_mday`.
        /// Day of the month - [1, 31]
        month_day: c_int = 0,
        /// Renamed from `tm_mon`.
        /// Months since January - [0, 11]
        month: c_int = 0,
        /// Renamed from `tm_year`.
        /// Years since 1900
        year: c_int = 0,
        /// Renamed from `tm_wday`.
        /// Days since Sunday - [0, 6]
        week_day: c_int = 0,
        /// Renamed from `tm_yday`.
        /// Days since January 1 - [0, 365]
        year_day: c_int = 0,
        /// Renamed from `tm_isdst`.
        /// Daylight Savings Time flag. The value is positive if DST is in effect, zero if not
        /// and negative if no information is available.
        is_dst: c_int = -1,
        /// Renamed from BSD standard `tm_gmtoff`
        /// Seconds east of UTC
        gmtoff: c_long = 0,
        /// Renamed from BSD standard `tm_zone`
        /// Timezone abbreviation, pointer to a C string
        zone: [*c]const u8 = undefined,
    };

    // pub const Time = uiDateTimePickerTime;
    pub fn Time(d: *DateTimePicker) struct_tm {
        var tm: struct_tm = undefined;
        d.uiDateTimePickerTime(&tm);
        return tm;
    }
    pub const SetTime = uiDateTimePickerSetTime;
    pub fn OnChanged(self: *Self, comptime T: type, comptime E: type, comptime f: *const fn (*Self, ?*T) E!void, userdata: ?*T) void {
        const callback = struct {
            fn callback(self_opt: ?*Self, t_opt: ?*anyopaque) callconv(.c) void {
                const err_ctx = ErrorContext{ .DateTimePickerOnChanged = self_opt };
                const s = self_opt orelse return error_handler(err_ctx, t_opt, error.LibUIPassedNullPointer);
                f(s, @as(?*T, @ptrCast(@alignCast(t_opt)))) catch |err| error_handler(err_ctx, t_opt, err);
            }
        }.callback;
        uiDateTimePickerOnChanged(self, callback, userdata);
    }
    pub const TypeEnum = enum {
        DateTime,
        Date,
        Time,
    };
    pub fn New(t: TypeEnum) !*DateTimePicker {
        return switch (t) {
            .DateTime => uiNewDateTimePicker(),
            .Date => uiNewDatePicker(),
            .Time => uiNewTimePicker(),
        } orelse error.InitDateTimePicker;
    }
};

/// `Checkbox` is a clickable control that toggles between an off and on state.
pub const Checkbox = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }

    pub extern fn uiCheckboxText(c: *Checkbox) [*:0]u8;
    pub extern fn uiCheckboxSetText(c: *Checkbox, text: [*:0]const u8) void;
    pub extern fn uiCheckboxOnToggled(c: *Checkbox, f: ?*const fn (*Checkbox, ?*anyopaque) callconv(.c) void, data: ?*anyopaque) void;
    pub extern fn uiCheckboxChecked(c: *Checkbox) c_int;
    pub extern fn uiCheckboxSetChecked(c: *Checkbox, checked: c_int) void;
    pub extern fn uiNewCheckbox(text: [*:0]const u8) ?*Checkbox;

    pub const Text = uiCheckboxText;
    pub const SetText = uiCheckboxText;

    pub fn OnToggled(self: *Self, comptime T: type, comptime E: type, comptime f: *const fn (*Self, ?*T) E!void, userdata: ?*T) void {
        const callback = struct {
            fn callback(self_opt: ?*Self, t_opt: ?*anyopaque) callconv(.c) void {
                const err_ctx = ErrorContext{ .CheckboxOnToggled = self_opt };
                const s = self_opt orelse return error_handler(err_ctx, t_opt, error.LibUIPassedNullPointer);
                f(s, @as(?*T, @ptrCast(@alignCast(t_opt)))) catch |err| error_handler(err_ctx, t_opt, err);
            }
        }.callback;
        uiCheckboxOnToggled(self, callback, userdata);
    }

    pub fn Checked(c: *Checkbox) bool {
        return uiCheckboxChecked(c) != 0;
    }
    pub fn SetChecked(c: *Checkbox, checked: bool) void {
        uiCheckboxSetChecked(c, @intFromBool(checked));
    }

    pub fn New(text: [*:0]const u8) !*Checkbox {
        const new_checkbox = uiNewCheckbox(text);
        if (new_checkbox == null) return error.InitCheckbox;
        return new_checkbox.?;
    }
};

/// Combobox is a control that allows users to select a single value from a predefined list.
/// Uses a dropdown to display the selection to the user.
pub const Combobox = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }

    pub extern fn uiComboboxAppend(c: *Combobox, text: [*:0]const u8) void;
    pub extern fn uiComboboxInsertAt(c: *Combobox, index: c_int, text: [*:0]const u8) void;
    pub extern fn uiComboboxDelete(c: *Combobox, index: c_int) void;
    pub extern fn uiComboboxClear(c: *Combobox) void;
    pub extern fn uiComboboxNumItems(c: *Combobox) c_int;
    pub extern fn uiComboboxSelected(c: *Combobox) c_int;
    pub extern fn uiComboboxSetSelected(c: *Combobox, index: c_int) void;
    pub extern fn uiComboboxOnSelected(c: *Combobox, f: ?*const fn (?*Combobox, ?*anyopaque) callconv(.c) void, data: ?*anyopaque) void;
    pub extern fn uiNewCombobox() ?*Combobox;

    pub const Append = uiComboboxAppend;
    pub const InsertAt = uiComboboxInsertAt;
    pub const Delete = uiComboboxDelete;
    pub const Clear = uiComboboxClear;
    pub const NumItems = uiComboboxNumItems;
    pub const Selected = uiComboboxSelected;
    pub const SetSelected = uiComboboxSetSelected;
    pub fn OnSelected(self: *Self, comptime T: type, comptime E: type, comptime f: *const fn (*Self, ?*T) E!void, userdata: ?*T) void {
        const callback = struct {
            fn callback(self_opt: ?*Self, t_opt: ?*anyopaque) callconv(.c) void {
                const err_ctx = ErrorContext{ .ComboboxOnSelected = self_opt };
                const s = self_opt orelse return error_handler(err_ctx, t_opt, error.LibUIPassedNullPointer);
                f(s, @as(?*T, @ptrCast(@alignCast(t_opt)))) catch |err| error_handler(err_ctx, t_opt, err);
            }
        }.callback;
        uiComboboxOnSelected(self, callback, userdata);
    }
    pub fn New() !*Combobox {
        return uiNewCombobox() orelse error.InitCombobox;
    }
};

/// RadioButtons is a control that allows users to select from a list of values. All values
/// are shown on the screen at the same time, and an visual indicator is used to inform the
/// use of the current selection.
pub const RadioButtons = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }

    pub extern fn uiRadioButtonsAppend(r: *RadioButtons, text: [*:0]const u8) void;
    pub extern fn uiRadioButtonsSelected(r: *RadioButtons) c_int;
    pub extern fn uiRadioButtonsSetSelected(r: *RadioButtons, index: c_int) void;
    pub extern fn uiRadioButtonsOnSelected(r: *RadioButtons, f: ?*const fn (?*RadioButtons, ?*anyopaque) callconv(.c) void, data: ?*anyopaque) void;
    pub extern fn uiNewRadioButtons() ?*RadioButtons;

    pub const Append = uiRadioButtonsAppend;
    pub const Selected = uiRadioButtonsSelected;
    pub const SetSelected = uiRadioButtonsSetSelected;
    pub fn OnSelected(self: *Self, comptime T: type, comptime E: type, comptime f: *const fn (*Self, ?*T) E!void, userdata: ?*T) void {
        const callback = struct {
            fn callback(self_opt: ?*Self, t_opt: ?*anyopaque) callconv(.c) void {
                const err_ctx = ErrorContext{ .RadioButtonsOnSelected = self_opt };
                const s = self_opt orelse return error_handler(err_ctx, t_opt, error.LibUIPassedNullPointer);
                f(s, @as(?*T, @ptrCast(@alignCast(t_opt)))) catch |err| error_handler(err_ctx, t_opt, err);
            }
        }.callback;
        uiRadioButtonsOnSelected(self, callback, userdata);
    }
    pub fn New() !*RadioButtons {
        return uiNewRadioButtons() orelse error.InitRadioButtons;
    }
};

/// Slider is a control that allows users to select a value within a specified range.
pub const Slider = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }

    pub extern fn uiSliderValue(s: *Slider) c_int;
    pub extern fn uiSliderSetValue(s: *Slider, value: c_int) void;
    pub extern fn uiSliderHasToolTip(s: *Slider) c_int;
    pub extern fn uiSliderSetHasToolTip(s: *Slider, hasToolTip: c_int) void;
    pub extern fn uiSliderOnChanged(s: *Slider, f: ?*const fn (*Slider, ?*anyopaque) callconv(.c) void, data: ?*anyopaque) void;
    pub extern fn uiSliderOnReleased(s: *Slider, f: ?*const fn (*Slider, ?*anyopaque) callconv(.c) void, data: ?*anyopaque) void;
    pub extern fn uiSliderSetRange(s: *Slider, min: c_int, max: c_int) void;
    pub extern fn uiNewSlider(min: c_int, max: c_int) ?*Slider;

    pub const Value = uiSliderValue;
    pub const SetValue = uiSliderSetValue;
    pub fn HasToolTip(s: *Slider) bool {
        return uiSliderHasToolTip(s) != 0;
    }
    pub fn SetHasToolTip(s: *Slider, hasToolTip: bool) void {
        uiSliderSetHasToolTip(s, @intFromBool(hasToolTip));
    }
    pub fn OnChanged(self: *Self, comptime T: type, comptime E: type, comptime f: *const fn (*Self, ?*T) E!void, userdata: ?*T) void {
        const callback = struct {
            fn callback(self_opt: ?*Self, t_opt: ?*anyopaque) callconv(.c) void {
                const err_ctx = ErrorContext{ .SliderOnChanged = self_opt };
                const s = self_opt orelse return error_handler(err_ctx, t_opt, error.LibUIPassedNullPointer);
                f(s, @as(?*T, @ptrCast(@alignCast(t_opt)))) catch |err| error_handler(err_ctx, t_opt, err);
            }
        }.callback;
        uiSliderOnChanged(self, callback, userdata);
    }
    pub fn OnReleased(self: *Self, comptime T: type, comptime E: type, comptime f: *const fn (*Self, ?*T) E!void, userdata: ?*T) void {
        const callback = struct {
            fn callback(self_opt: ?*Self, t_opt: ?*anyopaque) callconv(.c) void {
                const err_ctx = ErrorContext{ .SliderOnReleased = self_opt };
                const s = self_opt orelse return error_handler(err_ctx, t_opt, error.LibUIPassedNullPointer);
                f(s, @as(?*T, @ptrCast(@alignCast(t_opt)))) catch |err| error_handler(err_ctx, t_opt, err);
            }
        }.callback;
        uiSliderOnReleased(self, callback, userdata);
    }
    pub const SetRange = uiSliderSetRange;
    pub fn New(min: c_int, max: c_int) !*Slider {
        return uiNewSlider(min, max) orelse error.InitSlider;
    }
};

/// Spinbox is a control for numerical input that allows users to either type in their
/// desired value or use up and down buttons to increment or decrement the value.
pub const Spinbox = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }

    pub extern fn uiSpinboxValue(s: *Spinbox) c_int;
    pub extern fn uiSpinboxValueDouble(s: *Spinbox) f64;
    pub extern fn uiSpinboxSetValue(s: *Spinbox, value: c_int) void;
    pub extern fn uiSpinboxSetValueDouble(s: *Spinbox, value: f64) void;
    pub extern fn uiSpinboxValueText(s: *Spinbox) [*:0]const u8;
    pub extern fn uiSpinboxOnChanged(s: *Spinbox, f: ?*const fn (?*Spinbox, ?*anyopaque) callconv(.c) void, data: ?*anyopaque) void;
    pub extern fn uiNewSpinbox(min: c_int, max: c_int) ?*Spinbox;
    pub extern fn uiNewSpinboxDouble(min: f64, max: f64, precision: c_int) ?*Spinbox;

    pub const Value = uiSpinboxValue;
    pub const ValueDouble = uiSpinboxValueDouble;
    pub const SetValue = uiSpinboxSetValue;
    pub const SetValueDouble = uiSpinboxSetValueDouble;
    pub const ValueText = uiSpinboxValueText;

    pub fn OnChanged(self: *Self, comptime T: type, comptime E: type, comptime f: *const fn (*Self, ?*T) E!void, userdata: ?*T) void {
        const callback = struct {
            fn callback(self_opt: ?*Self, t_opt: ?*anyopaque) callconv(.c) void {
                const err_ctx = ErrorContext{ .SpinboxOnChanged = self_opt };
                const s = self_opt orelse return error_handler(err_ctx, t_opt, error.LibUIPassedNullPointer);
                f(s, @as(?*T, @ptrCast(@alignCast(t_opt)))) catch |err| error_handler(err_ctx, t_opt, err);
            }
        }.callback;
        uiSpinboxOnChanged(self, callback, userdata);
    }

    pub const TypeEnum = union(enum) {
        Integer: struct { min: c_int, max: c_int },
        Double: struct { min: f64, max: f64, precision: c_int },
    };
    pub fn New(t: TypeEnum) !*Spinbox {
        return switch (t) {
            .Integer => |int| uiNewSpinbox(int.min, int.max),
            .Double => |double| uiNewSpinboxDouble(double.min, double.max, double.precision),
        } orelse error.InitSpinbox;
    }
};

pub const Control = ui.Control;
pub const error_handler = ui.error_handler;
pub const ErrorContext = ui.ErrorContext;

pub const ui = @import("ui.zig");
