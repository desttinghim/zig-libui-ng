const std = @import("std");
const ui = @This();

pub const InitData = struct {
    options: InitOptions,
    error_string: ?[*:0]const u8 = null,

    pub fn get_error(data: *const InitData) [*:0]const u8 {
        std.debug.assert(data.error_string != null);
        return data.error_string.?;
    }

    pub fn free_error(data: *InitData) void {
        const string = data.error_string orelse return;
        externs.uiFreeInitError(string);
    }
};

pub const InitError = error{
    /// This error has not been encoded into a Zig error - check the value
    /// of InitOptions.error_string to check the message returned by libui
    Other,
};

pub fn Init(options: *InitData) !void {
    const err = externs.uiInit(&options.options);
    if (err == null) return;
    options.error_string = err;
    return InitError.Other;
}

pub const Uninit = externs.uiUninit;
pub const Main = externs.uiMain;
pub const MainSteps = externs.uiMainSteps;
pub const MainStepWait = enum(c_int) {
    blocking = 1,
    nonblocking = 0,
};
pub const MainStepStatus = enum(c_int) {
    finished = 0,
    running = 1,
};
pub const MainStep = externs.uiMainStep;
pub const Quit = externs.uiQuit;

// Callback functions
pub const QueueMain = externs.uiQueueMain;

pub const TimerAction = enum(c_int) {
    disarm = 0,
    rearm = 1,
};
pub const Timer = externs.uiTimer;

pub const QuitAction = enum(c_int) {
    should_not_quit = 0,
    should_quit = 1,
};
pub const OnShouldQuit = externs.uiOnShouldQuit;
pub const FreeText = externs.uiFreeText;

pub const ForEach = enum(c_int) {
    Continue = 0,
    Stop = 1,
};

pub const InitOptions = extern struct {
    Size: usize,
};

pub const Control = extern struct {
    Signature: u32,
    OSSignature: u32,
    TypeSignature: u32,
    _Destroy: ?*const fn (*Control) callconv(.C) void,
    _Handle: ?*const fn (*Control) callconv(.C) usize,
    _Parent: ?*const fn (*Control) callconv(.C) *Control,
    _SetParent: ?*const fn (*Control, *Control) callconv(.C) void,
    _Toplevel: ?*const fn (*Control) callconv(.C) c_int,
    _Visible: ?*const fn (*Control) callconv(.C) c_int,
    _Show: ?*const fn (*Control) callconv(.C) void,
    _Hide: ?*const fn (*Control) callconv(.C) void,
    _Enabled: ?*const fn (*Control) callconv(.C) c_int,
    _Enable: ?*const fn (*Control) callconv(.C) void,
    _Disable: ?*const fn (*Control) callconv(.C) void,

    pub const Destroy = externs.uiControlDestroy;
    pub const Handle = externs.uiControlHandle;
    pub const Parent = externs.uiControlParent;
    pub const SetParent = externs.uiControlSetParent;
    pub const Show = externs.uiControlShow;
    pub const Hide = externs.uiControlHide;
    pub const Enable = externs.uiControlEnable;
    pub const Disable = externs.uiControlDisable;
    pub const Free = externs.uiFreeControl;
    pub const VerifySetParent = externs.uiControlVerifySetParent;
    pub fn Toplevel(c: *Control) bool {
        return externs.uiControlToplevel(c) == 1;
    }
    pub fn Visible(c: *Control) bool {
        return externs.uiControlVisible(c) == 1;
    }
    pub fn Enabled(c: *Control) bool {
        return externs.uiControlEnabled(c) == 1;
    }
    pub fn Alloc(n: usize, OSsig: u32, typesig: u32, typenamestr: [*:0]const u8) ?[*]Control {
        return externs.uiAllocControl(n, OSsig, typesig, typenamestr);
    }
    pub fn EnabledToUser(c: *Control) bool {
        return externs.uiControlEnabledToUser(c) == 1;
    }
};

pub const Window = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }

    pub const Title = externs.uiWindowTitle;
    pub const SetTitle = externs.uiWindowSetTitle;

    const Point = struct {
        x: c_int,
        y: c_int,
    };
    pub fn Position(w: *Window) Point {
        var point: Point = .{ .x = 0, .y = 0 };
        externs.uiWindowPosition(w, &point.x, &point.y);
        return point;
    }

    pub fn SetPosition(w: *Window, x: c_int, y: c_int) void {
        externs.uiWindowSetPosition(w, x, y);
    }

    pub const Size = struct {
        width: c_int,
        height: c_int,
    };
    pub fn ContentSize(w: *Window) Size {
        var size: Size = .{ .width = 0, .height = 0 };
        externs.uiWindowContentSize(w, &size.width, &size.height);
        return size;
    }

    pub fn SetContentSize(w: *Window, width: c_int, height: c_int) void {
        externs.uiWindowSetContentSize(w, width, height);
    }

    pub fn Fullscreen(w: *Window) bool {
        return externs.uiWindowFullscreen(w) == 1;
    }

    pub fn SetFullscreen(w: *Window, fullscreen: bool) void {
        externs.uiWindowSetFullscreen(w, @intFromBool(fullscreen));
    }

    pub fn Focused(w: *Window) bool {
        return externs.uiWindowFocused(w) == 1;
    }

    pub fn Borderless(w: *Window) bool {
        return externs.uiWindowBorderless(w) == 1;
    }

    pub fn SetBorderless(w: *Window, borderless: bool) void {
        externs.uiWindowSetBorderless(w, @intFromBool(borderless));
    }

    pub const SetChild = externs.uiWindowSetChild;

    pub fn Margined(w: *Window) bool {
        externs.uiWindowMargined(w) == 1;
    }

    pub fn SetMargined(w: *Window, margined: bool) void {
        externs.uiWindowSetMargined(w, @intFromBool(margined));
    }

    pub fn Resizeable(w: *Window) bool {
        return externs.uiWindowResizeable(w);
    }

    pub fn SetResizeable(w: *Window, resizeable: bool) void {
        externs.uiWindowSetResizeable(w, @intFromBool(resizeable));
    }

    const HasMenubar = enum(c_int) {
        show_menubar = 0,
        hide_menubar = 1,
    };
    pub fn New(title: [*:0]const u8, width: c_int, height: c_int, hasMenubar: HasMenubar) !*Window {
        const new_window = externs.uiNewWindow(title, width, height, @intFromEnum(hasMenubar));
        if (new_window == null) return error.InitWindow;
        return new_window.?;
    }

    pub fn OnPositionChanged(window: *Window, comptime T: type, comptime f: *const fn (*Window, ?*T) void, userdata: ?*T) void {
        const callback = struct {
            fn callback(window_opt: ?*Window, t_opt: ?*anyopaque) callconv(.C) void {
                const w = window_opt orelse @panic("libui-ng sent null window_opt");
                f(w, @as(?*T, @ptrCast(@alignCast(t_opt))));
            }
        }.callback;
        externs.uiWindowOnPositionChanged(window, callback, userdata);
    }

    pub fn OnContentSizeChanged(window: *Window, comptime T: type, comptime f: *const fn (*Window, ?*T) void, userdata: ?*T) void {
        const callback = struct {
            fn callback(window_opt: ?*Window, t_opt: ?*anyopaque) callconv(.C) void {
                const w = window_opt orelse @panic("libui-ng sent null window_opt");
                f(w, @as(?*T, @ptrCast(@alignCast(t_opt))));
            }
        }.callback;
        externs.uiWindowOnContentSizeChanged(window, callback, userdata);
    }

    pub const ClosingAction = enum(c_int) {
        should_not_close = 0,
        should_close = 1,
    };
    pub fn OnClosing(window: *Window, comptime T: type, comptime f: *const fn (*Window, ?*T) ClosingAction, userdata: ?*T) void {
        const callback = struct {
            fn callback(window_opt: ?*Window, t_opt: ?*anyopaque) callconv(.C) ClosingAction {
                const w = window_opt orelse @panic("libui-ng sent null window_opt");
                return f(w, @as(?*T, @ptrCast(@alignCast(t_opt))));
            }
        }.callback;
        externs.uiWindowOnClosing(window, callback, userdata);
    }

    pub fn OnFocusChanged(window: *Window, comptime T: type, comptime f: *const fn (*Window, ?*T) void, userdata: ?*T) void {
        const callback = struct {
            fn callback(window_opt: ?*Window, t_opt: ?*anyopaque) callconv(.C) void {
                const w = window_opt orelse @panic("libui-ng sent null window_opt");
                f(w, @as(?*T, @ptrCast(@alignCast(t_opt))));
            }
        }.callback;
        externs.uiWindowOnFocusChanged(window, callback, userdata);
    }

    pub const OpenFile = externs.uiOpenFile;
    pub const OpenFileWithParams = externs.uiOpenFileWithParams;
    pub const OpenFolder = externs.uiOpenFolder;
    pub const SaveFile = externs.uiSaveFile;
    pub const SaveFileWithParams = externs.uiSaveFileWithParams;
    pub const MsgBox = externs.uiMsgBox;
    pub const MsgBoxError = externs.uiMsgBoxError;
};

pub const Button = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }

    pub const Text = externs.uiButtonText;
    pub const SetText = externs.uiButtonSetText;

    pub fn OnClicked(self: *Self, comptime T: type, comptime f: *const fn (*Self, ?*T) void, userdata: ?*T) void {
        const callback = struct {
            fn callback(window_opt: ?*Self, t_opt: ?*anyopaque) callconv(.C) void {
                const w = window_opt orelse @panic("libui-ng sent null window_opt");
                const t = @as(?*T, @ptrCast(@alignCast(t_opt))) orelse @panic("libui-ng sent null userdata");
                f(w, t);
            }
        }.callback;
        externs.uiButtonOnClicked(self, callback, userdata);
    }

    pub fn New(text: [*:0]const u8) !*Button {
        var new_button = externs.uiNewButton(text);
        if (new_button == null) return error.InitButton;
        return new_button.?;
    }
};

pub const Box = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }
    pub const Stretchy = enum(c_int) {
        stretch = 1,
        dont_stretch = 0,
    };

    pub const Append = externs.uiBoxAppend;
    pub const NumChildren = externs.uiBoxNumChildren;
    pub const Delete = externs.uiBoxDelete;

    pub fn Padded(b: *Box) bool {
        return externs.uiBoxPadded(b) == 1;
    }

    pub fn SetPadded(b: *Box, padded: bool) void {
        externs.uiBoxSetPadded(b, @intFromBool(padded));
    }

    pub const Orientation = enum {
        Vertical,
        Horizontal,
    };
    pub fn New(orientation: Orientation) !*Box {
        const new_box = switch (orientation) {
            .Vertical => externs.uiNewVerticalBox(),
            .Horizontal => externs.uiNewHorizontalBox(),
        };
        if (new_box == null) return error.InitBox;
        return new_box.?;
    }
};

pub const Checkbox = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }

    pub const Text = externs.uiCheckboxText;
    pub const SetText = externs.uiCheckboxText;

    pub fn OnToggled(self: *Self, comptime T: type, f: *const fn (*Self, ?*T) void, userdata: ?*T) void {
        const callback = struct {
            fn callback(self_opt: ?*Self, t_opt: ?*anyopaque) callconv(.C) void {
                const s = self_opt orelse @panic("libui-ng sent null checkbox");
                const t = @as(?*T, @ptrCast(@alignCast(t_opt))) orelse @panic("libui-ng sent null userdata");
                f(s, t);
            }
        }.callback;
        externs.uiButtonOnFocusChanged(self, callback, userdata);
    }

    pub fn Checked(c: *Checkbox) bool {
        return externs.uiCheckboxChecked(c) == 1;
    }
    pub fn SetChecked(c: *Checkbox, checked: bool) void {
        externs.uiCheckboxSetChecked(c, @intFromBool(checked));
    }

    pub fn New(text: [*:0]const u8) !*Checkbox {
        const new_checkbox = externs.uiNewCheckbox(text);
        if (new_checkbox == null) return error.InitCheckbox;
        return new_checkbox.?;
    }
};

pub const Entry = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }
    pub const Text = externs.uiEntryText;
    pub const SetText = externs.uiEntryText;
    pub const OnChanged = externs.uiEntryOnChanged;

    pub fn uiEntryReadOnly(e: *Entry) bool {
        return externs.uiEntryReadOnly(e) == 1;
    }
    pub fn uiEntrySetReadOnly(e: *Entry, readonly: c_int) void {
        return externs.uiEntrySetReadOnly(e, @intFromBool(readonly));
    }
    pub const Type = enum {
        Entry,
        Password,
        Search,
    };
    pub fn New(t: Type) !*Entry {
        const new_entry = switch (t) {
            .Entry => externs.uiNewEntry(),
            .Password => externs.uiNewPasswordEntry(),
            .Search => externs.uiNewSearchEntry(),
        };
        if (new_entry == null) return error.InitEntry;
        return new_entry.?;
    }
};

pub const Label = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }
    pub const Text = externs.uiLabelText;
    pub const SetText = externs.uiLabelSetText;
    pub fn New(text: [*:0]const u8) !*Label {
        return externs.uiNewLabel(text) orelse error.InitLabel;
    }
};

pub const Tab = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }
    pub const Append = externs.uiTabAppend;
    pub const InsertAt = externs.uiTabInsertAt;
    pub const Delete = externs.uiTabDelete;
    pub const NumPages = externs.uiTabNumPages;

    pub fn Margined(t: *Tab, index: c_int) bool {
        return externs.uiTabMargined(t, index) == 1;
    }
    pub fn SetMargined(t: *Tab, index: c_int, margined: bool) void {
        return externs.uiTabsetMargined(t, index, @intFromBool(margined));
    }
    pub fn New() !*Tab {
        return externs.uiNewTab() orelse error.InitTab;
    }
};

pub const Group = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }
    pub const Title = externs.uiGroupTitle;
    pub const SetTitle = externs.uiGroupSetTitle;
    pub const SetChild = externs.uiGroupSetChild;
    pub fn Margined(g: *Group) bool {
        return externs.uiGroupMargined(g) == 1;
    }
    pub fn SetMargined(g: *Group, margined: bool) void {
        externs.uiGroupSetMargined(g, margined);
    }
    pub fn New(title: [*:0]const u8) !*Group {
        return externs.uiNewGroup(title) orelse error.InitGroup;
    }
};

pub const Spinbox = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }
    pub const Value = externs.uiSpinboxValue;
    pub const ValueDouble = externs.uiSpinboxValueDouble;
    pub const SetValue = externs.uiSpinboxSetValue;
    pub const SetValueDouble = externs.uiSpinboxSetValueDouble;
    pub const OnChanged = externs.uiSpinboxOnChanged;
    pub const Type = union(enum) {
        Integer: struct { min: c_int, max: c_int },
        Double: struct { min: f64, max: f64, precision: c_int },
    };
    pub fn New(t: Type) !*Spinbox {
        return switch (t) {
            .Integer => |int| externs.uiNewSpinbox(int.min, int.max),
            .Double => |double| externs.uiNewSpinboxDouble(double.min, double.max, double.precision),
        } orelse error.InitSpinbox;
    }
};

pub const Slider = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }
    pub const Value = externs.uiSliderValue;
    pub const SetValue = externs.uiSliderSetValue;
    pub fn HasToolTip(s: *Slider) bool {
        return externs.uiSliderHasToolTip(s) == 1;
    }
    pub fn SetHasToolTip(s: *Slider, hasToolTip: bool) void {
        externs.uiSliderSetHasToolTip(s, @intFromBool(hasToolTip));
    }
    pub const OnChanged = externs.uiSliderOnChanged;
    pub const OnReleased = externs.uiSliderOnReleased;
    pub const SetRange = externs.uiSliderSetRange;
    pub fn New(min: c_int, max: c_int) !*Slider {
        return externs.uiNewSlider(min, max) orelse error.InitSlider;
    }
};

pub const ProgressBar = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }
    pub const Value = externs.uiProgressBarValue;
    pub const SetValue = externs.uiProgressBarSetValue;
    pub fn uiNewProgressBar() !*ProgressBar {
        return externs.uiNewProgressBar() orelse error.InitProgressBar;
    }
};

pub const Separator = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }
    pub const Type = enum {
        Horizontal,
        Vertical,
    };
    pub fn New(t: Type) !*Separator {
        return switch (t) {
            .Horizontal => externs.uiNewHorizontalSeparator(),
            .Vertical => externs.uiNewVerticalSeparator(),
        } orelse error.InitSeparator;
    }
};

pub const Combobox = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }
    pub const Append = externs.uiComboboxAppend;
    pub const InsertAt = externs.uiComboboxInsertAt;
    pub const Delete = externs.uiComboboxDelete;
    pub const Clear = externs.uiComboboxClear;
    pub const NumItems = externs.uiComboboxNumItems;
    pub const Selected = externs.uiComboboxSelected;
    pub const SetSelected = externs.uiComboboxSetSelected;
    pub const OnSelected = externs.uiComboboxOnSelected;
    pub fn New() !*Combobox {
        return externs.uiNewCombobox() orelse error.InitCombobox;
    }
};

pub const EditableCombobox = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }
    pub const Append = externs.uiEditableComboboxAppend;
    pub const Text = externs.uiEditableComboboxText;
    pub const SetText = externs.uiEditableComboboxSetText;
    pub const OnChanged = externs.uiEditableComboboxOnChanged;
    pub fn New() !*EditableCombobox {
        return externs.uiNewEditableCombobox() orelse error.InitEditableCombobox;
    }
};

pub const RadioButtons = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }
    pub const Append = externs.uiRadioButtonAppend;
    pub const Selected = externs.uiRadioButtonSelected;
    pub const SetSelected = externs.uiRadioButtonSetSelected;
    pub const OnSelected = externs.uiRadioButtonOnSelected;
    pub fn New() !*RadioButtons {
        return externs.uiNewRadioButtons() orelse error.InitRadioButtons;
    }
};

pub const struct_tm = opaque {};
pub const tm = struct_tm;

pub const DateTimePicker = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }
    pub const Time = externs.uiDateTimePickerTime;
    pub const SetTime = externs.uiDateTimePickerSetTime;
    pub const OnChanged = externs.uiDateTimePickerOnChanged;
    pub const Type = enum {
        DateTime,
        Date,
        Time,
    };
    pub fn New(t: Type) !*DateTimePicker {
        return switch (t) {
            .DateTime => externs.uiNewDateTimePicker(),
            .Date => externs.uiNewDatePicker(),
            .Time => externs.uiNewTimePicker(),
        } orelse error.InitDateTimePicker;
    }
};

pub const MultilineEntry = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }
    pub const Text = externs.uiMultilineEntryText;
    pub const SetText = externs.uiMultilineEntrySetText;
    pub const Append = externs.uiMultilineEntryAppend;
    pub const OnChanged = externs.uiMultilineEntryOnChanged;
    pub fn ReadOnly(e: *MultilineEntry) bool {
        return externs.uiMultilineEntryReadOnly(e) == 1;
    }
    pub fn SetReadOnly(e: *MultilineEntry, readonly: bool) void {
        return externs.uiMultilineEntrySetReadOnly(e, @intFromBool(readonly));
    }
    pub const Type = enum {
        Wrapping,
        NonWrapping,
    };
    pub fn New(t: Type) !*MultilineEntry {
        return switch (t) {
            .Wrapping => externs.uiNewMultilineEntry(),
            .NonWrapping => externs.uiNewNonWrappingMultilineEntry(),
        } orelse error.InitMultilineEntry;
    }
};

pub const MenuItem = opaque {
    pub const Enable = externs.uiMenuItemEnable;
    pub const Disable = externs.uiMenuItemDisable;
    pub const OnClicked = externs.uiMenuItemOnClicked;
    pub fn Checked(m: *MenuItem) bool {
        return externs.uiMenuItemChecked(m) == 1;
    }
    pub fn SetChecked(m: *MenuItem, checked: bool) void {
        return externs.uiMenuItemSetChecked(m, @intFromBool(checked));
    }
};

pub const Menu = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }
    pub fn AppendItem(m: *Menu, name: [*:0]const u8) !*MenuItem {
        return externs.uiMenuAppendItem(m, name) orelse error.InitMenuItem;
    }
    pub fn AppendCheckItem(m: *Menu, name: [*:0]const u8) !*MenuItem {
        return externs.uiMenuAppendCheckItem(m, name) orelse error.InitMenuItem;
    }
    pub fn AppendQuitItem(m: *Menu) !*MenuItem {
        return externs.uiMenuAppendQuitItem(m) orelse error.InitMenuItem;
    }
    pub fn AppendPreferencesItem(m: *Menu) !*MenuItem {
        return externs.uiMenuAppendPreferencesItem(m) orelse error.InitMenuItem;
    }
    pub fn AppendAboutItem(m: *Menu) !*MenuItem {
        return externs.uiMenuAppendAboutItem(m) orelse error.InitMenuItem;
    }
    pub const AppendSeparator = externs.uiMenuAppendSeparator;
    pub fn New(name: [*:0]const u8) !*Menu {
        return externs.uiNewMenu(name) orelse error.InitMenu;
    }
};

pub const FileDialogParams = extern struct {
    pub const Filter = extern struct {
        name: [*:0]const u8,
        patternCount: usize,
        patterns: *[*:0]const u8,
    };
    defaultPath: [*:0]const u8,
    defaultName: [*:0]const u8,
    filterCount: usize,
    filters: *const Filter,
};

pub const Area = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }
    pub const SetSize = externs.uiAreaSetSize;
    pub const QueueRedrawAll = externs.uiAreaQueueRedrawAll;
    pub const ScrollTo = externs.uiAreaScrollTo;
    pub const BeginUserWindowMove = externs.uiAreaBeginUserWindowMove;
    pub const WindowResizeEdge = enum(c_int) {
        Left = 0,
        Top = 1,
        Right = 2,
        Bottom = 3,
        TopLeft = 4,
        TopRight = 5,
        BottomLeft = 6,
        BottomRight = 6,
    };
    pub const BeginUserWindowResize = externs.uiAreaBeginUserWindowResize;

    pub const Modifiers = packed struct(c_uint) {
        Ctrl: bool,
        Alt: bool,
        Shift: bool,
        Super: bool,
        _unused: u28,
    };
    pub const MouseEvent = extern struct {
        X: f64,
        Y: f64,
        AreaWidth: f64,
        AreaHeight: f64,
        Down: c_int,
        Up: c_int,
        Count: c_int,
        Modifiers: Modifiers,
        Held1To64: u64,
    };
    pub const KeyEvent = extern struct {
        Key: u8,
        ExtKey: ExtKey,
        Modifier: Modifiers,
        Modifiers: Modifiers,
        Up: c_int,

        pub const ExtKey = enum(c_int) {
            Escape = 1,
            Insert = 2,
            Delete = 3,
            Home = 4,
            End = 5,
            PageUp = 6,
            PageDown = 7,
            Up = 8,
            Down = 9,
            Left = 10,
            Right = 11,
            F1 = 12,
            F2 = 13,
            F3 = 14,
            F4 = 15,
            F5 = 16,
            F6 = 17,
            F7 = 18,
            F8 = 19,
            F9 = 20,
            F10 = 21,
            F11 = 22,
            F12 = 23,
            N0 = 24,
            N1 = 25,
            N2 = 26,
            N3 = 27,
            N4 = 28,
            N5 = 29,
            N6 = 30,
            N7 = 31,
            N8 = 32,
            N9 = 33,
            NDot = 34,
            NEnter = 35,
            NAdd = 36,
            NSubtract = 37,
            NMultiply = 38,
            NDivide = 39,
        };
    };

    pub const Handler = extern struct {
        Draw: *const fn (*Handler, *Area, *Draw.Params) callconv(.C) void,
        MouseEvent: *const fn (*Handler, *Area, *MouseEvent) callconv(.C) void,
        MouseCrossed: *const fn (*Handler, *Area, c_int) callconv(.C) void,
        DragBroken: *const fn (*Handler, *Area) callconv(.C) void,
        KeyEvent: *const fn (*Handler, *Area, *KeyEvent) callconv(.C) c_int,

        pub const Type = union(enum) {
            Area,
            Scrolling: struct {
                width: c_int,
                height: c_int,
            },
        };
        pub fn New(handler: *Handler, t: Type) !*Area {
            return switch (t) {
                .Area => externs.uiNewArea(handler),
                .Scrolling => |params| externs.uiNewScrollingArea(handler, params.width, params.height),
            } orelse error.InitArea;
        }
    };

    pub const Draw = opaque {
        pub const Context = opaque {
            pub const Stroke = externs.uiDrawStroke;
            pub const Fill = externs.uiDrawStroke;
            pub const Text = externs.uiDrawStroke;
        };
        pub const Params = extern struct {
            Context: ?*Context,
            AreaWidth: f64,
            AreaHeight: f64,
            ClipX: f64,
            ClipY: f64,
            ClipWidth: f64,
            ClipHeight: f64,
        };

        pub const Path = opaque {
            pub const FillMode = enum(c_int) {
                Winding = 0,
                Alternate = 1,
            };
            pub extern fn uiDrawNewPath(fillMode: Path.FillMode) ?*Path;
            pub extern fn uiDrawFreePath(p: *Path) void;
            pub extern fn uiDrawPathNewFigure(p: *Path, x: f64, y: f64) void;
            pub extern fn uiDrawPathNewFigureWithArc(p: *Path, xCenter: f64, yCenter: f64, radius: f64, startAngle: f64, sweep: f64, negative: c_int) void;
            pub extern fn uiDrawPathLineTo(p: *Path, x: f64, y: f64) void;
            pub extern fn uiDrawPathArcTo(p: *Path, xCenter: f64, yCenter: f64, radius: f64, startAngle: f64, sweep: f64, negative: c_int) void;
            pub extern fn uiDrawPathBezierTo(p: *Path, c1x: f64, c1y: f64, c2x: f64, c2y: f64, endX: f64, endY: f64) void;
            pub extern fn uiDrawPathCloseFigure(p: *Path) void;
            pub extern fn uiDrawPathAddRectangle(p: *Path, x: f64, y: f64, width: f64, height: f64) void;
            pub extern fn uiDrawPathEnded(p: *Path) c_int;
            pub extern fn uiDrawPathEnd(p: *Path) void;
        };

        pub const Brush = extern struct {
            Type: Type,
            R: f64,
            G: f64,
            B: f64,
            A: f64,
            X0: f64,
            Y0: f64,
            X1: f64,
            Y1: f64,
            OuterRadius: f64,
            Stops: *GradientStop,
            NumStops: usize,

            pub const Type = enum(c_int) {
                Solid = 0,
                LinearGradient = 1,
                RadialGradient = 2,
                Image = 3,
            };

            pub const GradientStop = extern struct {
                Pos: f64,
                R: f64,
                G: f64,
                B: f64,
                A: f64,
            };
        };

        pub const DefaultMiterLimit = @as(f64, 10.0);
        pub const StrokeParams = extern struct {
            Cap: LineCap,
            Join: LineJoin,
            Thickness: f64,
            MiterLimit: f64 = DefaultMiterLimit,
            Dashes: [*]f64,
            NumDashes: usize,
            DashPhase: f64,

            pub const LineCap = enum(c_int) {
                Flat = 0,
                Round = 1,
                Square = 2,
            };
            pub const LineJoin = enum(c_int) {
                Miter = 0,
                Round = 1,
                Bevel = 2,
            };
        };

        pub const Matrix = extern struct {
            M11: f64,
            M12: f64,
            M21: f64,
            M22: f64,
            M31: f64,
            M32: f64,

            pub extern fn uiDrawMatrixSetIdentity(m: *Matrix) void;
            pub extern fn uiDrawMatrixTranslate(m: *Matrix, x: f64, y: f64) void;
            pub extern fn uiDrawMatrixScale(m: *Matrix, xCenter: f64, yCenter: f64, x: f64, y: f64) void;
            pub extern fn uiDrawMatrixRotate(m: *Matrix, x: f64, y: f64, amount: f64) void;
            pub extern fn uiDrawMatrixSkew(m: *Matrix, x: f64, y: f64, xamount: f64, yamount: f64) void;
            pub extern fn uiDrawMatrixMultiply(dest: *Matrix, src: *Matrix) void;
            pub extern fn uiDrawMatrixInvertible(m: *Matrix) c_int;
            pub extern fn uiDrawMatrixInvert(m: *Matrix) c_int;
            pub extern fn uiDrawMatrixTransformPoint(m: *Matrix, x: *f64, y: *f64) void;
            pub extern fn uiDrawMatrixTransformSize(m: *Matrix, x: *f64, y: *f64) void;
        };
    };

    pub const TextLayout = opaque {
        pub const Params = extern struct {
            String: ?*AttributedString,
            DefaultFont: *FontDescriptor,
            Width: f64,
            Align: Align,

            pub const Align = enum(c_int) {
                Left = 0,
                Center = 1,
                Right = 2,
            };
        };

        pub const Free = externs.uiDrawFreeTextLayout;
        pub const Size = struct {
            x: f64,
            y: f64,
        };
        pub fn TextLayoutExtents(tl: *TextLayout) Size {
            var size: Size = .{ .x = 0, .y = 0 };
            externs.uiDrawTextLayoutExtents(tl, &size.width, &size.height);
            return size;
        }

        pub fn New(params: *TextLayout.Params) !*TextLayout {
            return externs.uiDrawNewTextLayout(params) orelse error.InitTextLayout;
        }
    };
};

pub const Attribute = opaque {
    pub const Type = enum(c_int) {
        Family = 0,
        Size = 1,
        Weight = 2,
        Italic = 3,
        Stretch = 4,
        Color = 5,
        Background = 6,
        Underline = 7,
        UnderlineColor = 8,
        Features = 9,
    };

    pub const TextWeight = enum(c_uint) {
        Minimum = 0,
        Thin = 100,
        UltraLight = 200,
        Light = 300,
        Book = 350,
        Normal = 400,
        Medium = 500,
        SemiBold = 600,
        Bold = 700,
        UltraBold = 800,
        Heavy = 900,
        UltraHeavy = 950,
        Maximum = 1000,
    };

    pub const TextItalic = enum(c_uint) {
        Normal = 0,
        Oblique = 1,
        Italic = 2,
    };

    pub const TextStretch = enum(c_int) {
        UltraCondensed = 0,
        ExtraCondensed = 1,
        Condensed = 2,
        SemiCondensed = 3,
        Normal = 4,
        SemiExpeanded = 5,
        Expanded = 6,
        ExtraExpanded = 7,
        UltraExpanded = 8,
    };

    pub const UnderlineType = enum(c_int) {
        None = 0,
        Single = 1,
        Double = 2,
        Suggestion = 3,
    };

    pub const UnderlineColorType = enum(c_int) {
        Custom = 0,
        Spelling = 1,
        Grammar = 2,
        Auxiliary = 3,
    };

    pub const Free = externs.uiFreeAttribute;
    pub const GetType = externs.uiAttributeGetType;
    const TypeOptions = union(Type) {
        Family: [*:0]const u8,
        Size: f64,
        Weight: TextWeight,
        Italic: TextItalic,
        Stretch: TextStretch,
        Color: struct { r: f64, g: f64, b: f64, a: f64 },
        Background: struct { r: f64, g: f64, b: f64, a: f64 },
        UnderlineType: UnderlineType,
        UnderlineColorType: struct { t: UnderlineColor, r: f64, g: f64, b: f64, a: f64 },
        Features,
    };
    pub fn New(t: Type) !*Attribute {
        return switch (t) {
            .Family => |family| externs.uiNewFamilyAttribute(family),
            .Size => |size| externs.uiNewSizeAttribute(size),
            .Weight => |weight| externs.uiNewWeightAttribute(weight),
            .Italic => |italic| externs.uiNewItalicAttribute(italic),
            .Stretch => |stretch| externs.uiNewStretchAttribute(stretch),
            .Color => |color| externs.uiNewColorAttribute(color.r, color.g, color.b, color.a),
            .Background => |background| externs.uiNewBackgroundAttribute(background.r, background.g, background.b, background.a),
            .UnderlineType => |underline| externs.uiNewUnderlineAttribute(underline),
            .UnderlineColorType => |underline_color| externs.uiNewUnderlineColorAttribute(underline_color.t, underline_color.r, underline_color.g, underline_color.b, underline_color.a),
            .Features => return error.InitFeaturesAttribute, // This attribute type cannot be constructed
        } orelse error.InitAttribute;
    }
    pub const Family = externs.uiAttributeFamily;
    pub const Size = externs.uiAttributeSize;
    pub const Weight = externs.uiAttributeWeight;
    pub const Italic = externs.uiAttributeItalic;
    pub const Stretch = externs.uiAttributeStretch;
    pub const Color = externs.uiAttributeColor;
    pub const Underline = externs.uiAttributeUnderline;
    pub const UnderlineColor = externs.uiAttributeUnderlineColor;
    pub const Features = externs.uiAttributeFeatures;
};

pub const OpenTypeFeatures = opaque {
    pub const ForEachFunc = *const fn (*const OpenTypeFeatures, u8, u8, u8, u8, u32, ?*anyopaque) callconv(.C) ui.ForEach;
    pub fn New() !*OpenTypeFeatures {
        return externs.uiNewOpenTypeFeatures() orelse error.InitOpenTypeFeatures;
    }
    pub const Free = externs.uiFreeOpenTypeFeatures;
    pub const Clone = externs.uiOpenTypeFeaturesClone;
    pub const Add = externs.uiOpenTypeFeaturesAdd;
    pub const Remove = externs.uiOpenTypeFeaturesRemove;
    pub const Get = externs.uiOpenTypeFeaturesGet;
    pub const ForEach = externs.uiOpenTypeFeaturesForEach;
    pub fn NewAttribute(otf: *const OpenTypeFeatures) !*Attribute {
        return externs.uiNewFeaturesAttribute(otf) orelse error.InitAttribute;
    }
};

pub const AttributedString = opaque {
    pub const ForEachAttributeFunc = *const fn (*const AttributedString, *const Attribute, usize, usize, ?*anyopaque) callconv(.C) ui.ForEach;
    pub fn New() !*AttributedString {
        return externs.uiNewAttributedString() orelse error.InitAttributedString;
    }
    pub const Free = externs.uiFreeAttributedString;
    pub const String = externs.uiAttributedStringString;
    pub const AppendUnattributed = externs.uiAttributedStringAppendUnattributed;
    pub const InsertAtUnattributed = externs.uiAttributedStringInsertAtUnattributed;
    pub const Delete = externs.uiAttributedStringDelete;
    pub const SetAttribute = externs.uiAttributedStringSetAttribute;
    pub const ForEachAttribute = externs.uiAttributedStringForEachAttribute;
    pub const NumGraphemes = externs.uiAttributedStringNumGraphemes;
    pub const ByteIndexToGrapheme = externs.uiAttributedStringByteIndexToGrapheme;
    pub const GraphemeToByteIndex = externs.uiAttributedStringGraphemeToByteIndex;
};

pub const FontDescriptor = extern struct {
    Family: *u8,
    Size: f64,
    Weight: Attribute.TextWeight,
    Italic: Attribute.TextItalic,
    Stretch: Attribute.TextStretch,
    pub const LoadControlFont = externs.uiLoadControlFont;
    pub const Free = externs.uiFreeFontDescriptor;
};

pub const FontButton = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }
    pub const Font = externs.uiFontButtonFont;
    pub const OnChanged = externs.uiFontButtonOnChanged;
    pub fn New() !*FontButton {
        return externs.uiNewFontButton() orelse error.InitFontButton;
    }
    pub const FreeFont = externs.uiFreeFontButtonFont;
};

pub const ColorButton = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }
    pub const Color = externs.uiColorButtonColor;
    pub const SetColor = externs.uiColorButtonSetColor;
    pub const OnChanged = externs.uiColorButtonOnChanged;
    pub fn New() !*ColorButton {
        return externs.uiNewColorButton() orelse error.InitColorButton;
    }
};

pub const Form = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }
    pub const Append = externs.uiFormAppend;
    pub const NumChildren = externs.uiFormNumChildren;
    pub const Delete = externs.uiFormDelete;
    pub fn Padded(f: *Form) bool {
        return externs.uiFormPadded(f) == 1;
    }
    pub fn SetPadded(f: *Form, padded: bool) void {
        externs.uiFormPadded(f, @intFromBool(padded));
    }
    pub fn New() !*Form {
        return externs.uiNewForm() orelse return error.InitForm;
    }
};

pub const Grid = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }
    pub const Align = enum(c_int) {
        Fill = 0,
        Start = 1,
        Cetner = 2,
        End = 3,
    };

    pub const At = enum(c_int) {
        Leading = 0,
        Top = 1,
        Trailing = 2,
        Bottom = 3,
    };

    pub const Append = externs.uiGridAppend;
    pub const InsertAt = externs.uiGridInsertAt;
    pub fn Padded(g: *Grid) bool {
        return externs.uiGridPadded(g) == 1;
    }
    pub fn SetPadded(g: *Grid, padded: bool) void {
        externs.uiGridSetPadded(g, @intFromBool(padded));
    }
    pub fn New() !*Grid {
        const new_grid = externs.uiNewGrid();
        if (new_grid == null) return error.InitGrid;
        return new_grid.?;
    }
};

/// Contains an image to be used as a TableValue. Not derived from Control.
pub const Image = opaque {
    pub const Append = externs.uiImageAppend;
    pub fn New() !*ui.Image {
        return externs.uiNewImage() orelse return error.InitImage;
    }
    pub const Free = externs.uiFreeImage;
};

pub const Table = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }
    pub const Value = opaque {
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
        pub const GetType = externs.uiTableValueGetType;
        pub const TypeParameters = union(Type) {
            String: [*:0]const u8,
            Image: *ui.Image,
            Int: c_int,
            Color: struct { r: f64, g: f64, b: f64, a: f64 },
        };
        pub fn New(t: TypeParameters) !*Value {
            return switch (t) {
                .String => |string| externs.uiNewTableValueString(string),
                .Image => |image| externs.uiNewTableValueImage(image),
                .Int => |int| externs.uiNewTableValueInt(int),
                .Color => |color| externs.uiNewTableValueColor(color.r, color.g, color.b, color.a),
            } orelse error.InitTableValue;
        }
        pub const String = externs.uiTableValueString;
        pub const Image = externs.uiTableValueImage;
        pub const Int = externs.uiTableValueInt;
        pub const Color = externs.uiTableValueColor;
    };
    pub const Model = opaque {
        pub const ColumnNeverEditable: c_int = -1;
        pub const ColumnAlwaysEditable: c_int = -2;
        pub const Handler = extern struct {
            NumColumns: *const fn (*Handler, *Model) callconv(.C) c_int,
            ColumnType: *const fn (*Handler, *Model, c_int) callconv(.C) Value.Type,
            NumRows: *const fn (*Handler, *Model) callconv(.C) c_int,
            CellValue: *const fn (*Handler, *Model, c_int, c_int) callconv(.C) ?*Value,
            SetCellValue: *const fn (*Handler, *Model, c_int, c_int, ?*const Value) callconv(.C) void,
        };
        pub fn New(mh: *Handler) *Model {
            return externs.uiNewTableModel(mh) orelse error.InitModel;
        }
        pub const Free = externs.uiFreeTableModel;
        pub const RowInserted = externs.uiTableModelRowInserted;
        pub const RowChanged = externs.uiTableModelRowChanged;
        pub const RowDeleted = externs.uiTableModelDeleted;
    };
    pub const TextColumnOptionalParams = extern struct {
        ColorModelColumn: c_int,
    };
    pub const ColumnParameters = union(enum) {
        Text: struct { text_column: c_int, editable_column: c_int, text_params: ?*TextColumnOptionalParams },
        Image: struct { image_column: c_int },
        ImageText: struct { image_column: c_int, text_column: c_int, editable_column: c_int, text_params: ?*TextColumnOptionalParams },
        Checkbox: struct { checkbox_column: c_int, editable_column: c_int },
        CheckboxText: struct { checkbox_column: c_int, checkbox_editable_column: c_int, text_column: c_int, text_editable_column: c_int, text_params: ?*TextColumnOptionalParams },
        ProgressBar: struct { progress_column: c_int },
        Button: struct { button_column: c_int, button_clickable_column: c_int },
    };
    pub fn AppendColumn(t: *Table, name: [*:0]const u8, params: ColumnParameters) void {
        switch (params) {
            .Text => |p| externs.uiTableAppendTextColumn(t, name, p.text_column, p.text_editable, p.text_params),
            .Image => |p| externs.uiTableAppendImageColumn(t, name, p.image_column),
            .ImageText => |p| externs.uiTableAppendImageTextColumn(t, name, p.image_column, p.text_column, p.text_editable_column, p.text_params),
            .Checkbox => |p| externs.uiTableAppendCheckboxColumn(t, name, p.checkbox_column, p.checkbox_editable_column),
            .CheckboxText => |p| externs.uiTableAppendCheckboxTextColumn(t, name, p.checkbox_column, p.checkbox_editable_column, p.text_column, p.text_editable_column, p.text_params),
            .ProgressBar => |p| externs.uiTableAppendProgressBarColumn(t, name, p.progress_column),
            .Button => |p| externs.uiTableAppendButtonColumn(t, name, p.button_column, p.button_clickable_column),
        }
    }
    pub fn uiTableHeaderVisible(t: *Table) bool {
        return externs.uiTableHeaderVisible(t) == 1;
    }
    pub fn uiTableHeaderSetVisible(t: *Table, visible: bool) void {
        externs.uiTableHeaderSetVisible(t, @intFromBool(visible));
    }
    pub const Params = extern struct {
        Model: *Model,
        RowBackgroundColorModelColumn: c_int,
    };
    pub fn New(params: *Params) !*Table {
        return externs.uiNewTable(params) orelse error.InitTable;
    }
    pub const OnRowClicked = externs.uiTableOnRowClicked;
    pub const OnRowDoubleClicked = externs.uiTableOnRowDoubleClicked;
    pub const HeaderSetSortIndicator = externs.uiTableHeaderSetSortIndicator;
    pub const HeaderSortIndicator = externs.uiTableHeaderSortIndicator;
    pub const HeaderOnClicked = externs.uiTableHeaderOnClicked;
    pub const ColumnWidth = externs.uiTableColumnWidth;
    pub const ColumnSetWidth = externs.uiTableColumnSetWidth;

    pub const SelectionMode = enum(c_int) {
        None = 0,
        ZeroOrOne = 1,
        One = 2,
        ZeroOrMany = 3,
    };

    pub const GetSelectionMode = externs.uiTableGetSelectionMode;
    pub const SetSelectionMode = externs.uiTableSetSelectionMode;
    pub const OnSelectionChanged = externs.uiTableOnSelectionChanged;

    pub const Selection = extern struct {
        NumRows: c_int,
        Rows: *c_int,
    };

    pub const GetSelection = externs.uiTableGetSelection;
    pub const SetSelection = externs.uiTableSetSelection;
    pub const Free = externs.uiFreeTable;
};

pub const Pi = @as(f64, 3.14159265358979323846264338327950288419716939937510582097494459);

pub const externs = struct {
    pub extern fn uiInit(options: *InitOptions) ?[*:0]const u8;
    pub extern fn uiUninit() void;
    pub extern fn uiFreeInitError(err: [*:0]const u8) void;

    pub extern fn uiMain() void;
    pub extern fn uiMainSteps() void;
    pub extern fn uiMainStep(wait: MainStepWait) MainStepStatus;
    pub extern fn uiQuit() void;
    pub extern fn uiQueueMain(f: ?*const fn (?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;
    pub extern fn uiTimer(milliseconds: c_int, f: ?*const fn (?*anyopaque) callconv(.C) TimerAction, data: ?*anyopaque) void;
    pub extern fn uiOnShouldQuit(f: ?*const fn (?*anyopaque) callconv(.C) QuitAction, data: ?*anyopaque) void;
    pub extern fn uiFreeText(text: *u8) void;

    pub extern fn uiControlDestroy(c: *Control) void;
    pub extern fn uiControlHandle(c: *Control) usize;
    pub extern fn uiControlParent(c: *Control) ?*Control;
    pub extern fn uiControlSetParent(c: *Control, parent: *Control) void;
    pub extern fn uiControlToplevel(c: *Control) c_int;
    pub extern fn uiControlVisible(c: *Control) c_int;
    pub extern fn uiControlShow(c: *Control) void;
    pub extern fn uiControlHide(c: *Control) void;
    pub extern fn uiControlEnabled(c: *Control) c_int;
    pub extern fn uiControlEnable(c: *Control) void;
    pub extern fn uiControlDisable(c: *Control) void;
    pub extern fn uiAllocControl(n: usize, OSsig: u32, typesig: u32, typenamestr: [*:0]const u8) ?[*]Control;
    pub extern fn uiFreeControl(c: *Control) void;
    pub extern fn uiControlVerifySetParent(c: *Control, parent: ?*Control) void;
    pub extern fn uiControlEnabledToUser(c: *Control) c_int;
    pub extern fn uiUserBugCannotSetParentOnToplevel(@"type": [*:0]const u8) void;

    pub extern fn uiWindowTitle(w: *Window) [*:0]const u8;
    pub extern fn uiWindowSetTitle(w: *Window, title: [*:0]const u8) void;
    pub extern fn uiWindowPosition(w: *Window, x: *c_int, y: *c_int) void;
    pub extern fn uiWindowSetPosition(w: *Window, x: c_int, y: c_int) void;
    pub extern fn uiWindowOnPositionChanged(w: *Window, f: ?*const fn (*Window, ?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;
    pub extern fn uiWindowContentSize(w: *Window, width: *c_int, height: *c_int) void;
    pub extern fn uiWindowSetContentSize(w: *Window, width: c_int, height: c_int) void;
    pub extern fn uiWindowFullscreen(w: *Window) c_int;
    pub extern fn uiWindowSetFullscreen(w: *Window, fullscreen: c_int) void;
    pub extern fn uiWindowOnContentSizeChanged(w: *Window, f: ?*const fn (*Window, ?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;
    pub extern fn uiWindowOnClosing(w: *Window, f: ?*const fn (*Window, ?*anyopaque) callconv(.C) Window.ClosingAction, data: ?*anyopaque) void;
    pub extern fn uiWindowOnFocusChanged(w: *Window, f: ?*const fn (*Window, ?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;
    pub extern fn uiWindowFocused(w: *Window) c_int;
    pub extern fn uiWindowBorderless(w: *Window) c_int;
    pub extern fn uiWindowSetBorderless(w: *Window, borderless: c_int) void;
    pub extern fn uiWindowSetChild(w: *Window, child: *Control) void;
    pub extern fn uiWindowMargined(w: *Window) c_int;
    pub extern fn uiWindowSetMargined(w: *Window, margined: c_int) void;
    pub extern fn uiWindowResizeable(w: *Window) c_int;
    pub extern fn uiWindowSetResizeable(w: *Window, resizeable: c_int) void;
    pub extern fn uiNewWindow(title: [*:0]const u8, width: c_int, height: c_int, hasMenubar: c_int) ?*Window;

    pub extern fn uiButtonText(b: *Button) [*:0]const u8;
    pub extern fn uiButtonSetText(b: *Button, text: [*:0]const u8) void;
    pub extern fn uiButtonOnClicked(b: *Button, f: ?*const fn (*Button, ?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;
    pub extern fn uiNewButton(text: [*:0]const u8) ?*Button;

    pub extern fn uiBoxAppend(b: *Box, child: *Control, stretchy: Box.Stretchy) void;
    pub extern fn uiBoxNumChildren(b: *Box) c_int;
    pub extern fn uiBoxDelete(b: *Box, index: c_int) void;
    pub extern fn uiBoxPadded(b: *Box) c_int;
    pub extern fn uiBoxSetPadded(b: *Box, padded: c_int) void;
    pub extern fn uiNewHorizontalBox() ?*Box;
    pub extern fn uiNewVerticalBox() ?*Box;

    pub extern fn uiCheckboxText(c: *Checkbox) [*:0]u8;
    pub extern fn uiCheckboxSetText(c: *Checkbox, text: [*:0]const u8) void;
    pub extern fn uiCheckboxOnToggled(c: *Checkbox, f: ?*const fn (*Checkbox, ?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;
    pub extern fn uiCheckboxChecked(c: *Checkbox) c_int;
    pub extern fn uiCheckboxSetChecked(c: *Checkbox, checked: c_int) void;
    pub extern fn uiNewCheckbox(text: [*:0]const u8) ?*Checkbox;

    pub extern fn uiEntryText(e: *Entry) [*:0]u8;
    pub extern fn uiEntrySetText(e: *Entry, text: [*:0]const u8) void;
    pub extern fn uiEntryOnChanged(e: *Entry, f: ?*const fn (*Entry, ?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;
    pub extern fn uiEntryReadOnly(e: *Entry) c_int;
    pub extern fn uiEntrySetReadOnly(e: *Entry, readonly: c_int) void;
    pub extern fn uiNewEntry() ?*Entry;
    pub extern fn uiNewPasswordEntry() ?*Entry;
    pub extern fn uiNewSearchEntry() ?*Entry;

    pub extern fn uiLabelText(l: *Label) [*:0]u8;
    pub extern fn uiLabelSetText(l: *Label, text: [*:0]const u8) void;
    pub extern fn uiNewLabel(text: [*:0]const u8) ?*Label;

    pub extern fn uiTabAppend(t: *Tab, name: [*:0]const u8, c: *Control) void;
    pub extern fn uiTabInsertAt(t: *Tab, name: [*:0]const u8, index: c_int, c: [*:0]Control) void;
    pub extern fn uiTabDelete(t: *Tab, index: c_int) void;
    pub extern fn uiTabNumPages(t: *Tab) c_int;
    pub extern fn uiTabMargined(t: *Tab, index: c_int) c_int;
    pub extern fn uiTabSetMargined(t: *Tab, index: c_int, margined: c_int) void;
    pub extern fn uiNewTab() ?*Tab;

    pub extern fn uiGroupTitle(g: *Group) [*:0]u8;
    pub extern fn uiGroupSetTitle(g: *Group, title: [*:0]const u8) void;
    pub extern fn uiGroupSetChild(g: *Group, c: *Control) void;
    pub extern fn uiGroupMargined(g: *Group) c_int;
    pub extern fn uiGroupSetMargined(g: *Group, margined: c_int) void;
    pub extern fn uiNewGroup(title: [*:0]const u8) ?*Group;

    pub extern fn uiSpinboxValue(s: *Spinbox) c_int;
    pub extern fn uiSpinboxValueDouble(s: *Spinbox) f64;
    pub extern fn uiSpinboxSetValue(s: *Spinbox, value: c_int) void;
    pub extern fn uiSpinboxSetValueDouble(s: *Spinbox, value: f64) void;
    pub extern fn uiSpinboxOnChanged(s: *Spinbox, f: ?*const fn (?*Spinbox, ?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;
    pub extern fn uiNewSpinbox(min: c_int, max: c_int) ?*Spinbox;
    pub extern fn uiNewSpinboxDouble(min: f64, max: f64, precision: c_int) ?*Spinbox;

    pub extern fn uiSliderValue(s: *Slider) c_int;
    pub extern fn uiSliderSetValue(s: *Slider, value: c_int) void;
    pub extern fn uiSliderHasToolTip(s: *Slider) c_int;
    pub extern fn uiSliderSetHasToolTip(s: *Slider, hasToolTip: c_int) void;
    pub extern fn uiSliderOnChanged(s: *Slider, f: ?*const fn (*Slider, ?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;
    pub extern fn uiSliderOnReleased(s: *Slider, f: ?*const fn (*Slider, ?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;
    pub extern fn uiSliderSetRange(s: *Slider, min: c_int, max: c_int) void;
    pub extern fn uiNewSlider(min: c_int, max: c_int) ?*Slider;

    pub extern fn uiProgressBarValue(p: *ProgressBar) c_int;
    pub extern fn uiProgressBarSetValue(p: *ProgressBar, n: c_int) void;
    pub extern fn uiNewProgressBar() ?*ProgressBar;

    pub extern fn uiNewHorizontalSeparator() ?*Separator;
    pub extern fn uiNewVerticalSeparator() ?*Separator;

    pub extern fn uiComboboxAppend(c: *Combobox, text: [*:0]const u8) void;
    pub extern fn uiComboboxInsertAt(c: *Combobox, index: c_int, text: [*:0]const u8) void;
    pub extern fn uiComboboxDelete(c: *Combobox, index: c_int) void;
    pub extern fn uiComboboxClear(c: *Combobox) void;
    pub extern fn uiComboboxNumItems(c: *Combobox) c_int;
    pub extern fn uiComboboxSelected(c: *Combobox) c_int;
    pub extern fn uiComboboxSetSelected(c: *Combobox, index: c_int) void;
    pub extern fn uiComboboxOnSelected(c: *Combobox, f: ?*const fn (?*Combobox, ?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;
    pub extern fn uiNewCombobox() ?*Combobox;

    pub extern fn uiEditableComboboxAppend(c: *EditableCombobox, text: [*:0]const u8) void;
    pub extern fn uiEditableComboboxText(c: *EditableCombobox) [*:0]const u8;
    pub extern fn uiEditableComboboxSetText(c: *EditableCombobox, text: [*:0]const u8) void;
    pub extern fn uiEditableComboboxOnChanged(c: *EditableCombobox, f: ?*const fn (?*EditableCombobox, ?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;
    pub extern fn uiNewEditableCombobox() ?*EditableCombobox;

    pub extern fn uiRadioButtonsAppend(r: *RadioButtons, text: [*:0]const u8) void;
    pub extern fn uiRadioButtonsSelected(r: *RadioButtons) c_int;
    pub extern fn uiRadioButtonsSetSelected(r: *RadioButtons, index: c_int) void;
    pub extern fn uiRadioButtonsOnSelected(r: *RadioButtons, f: ?*const fn (?*RadioButtons, ?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;
    pub extern fn uiNewRadioButtons() ?*RadioButtons;

    pub extern fn uiDateTimePickerTime(d: *DateTimePicker, time: *struct_tm) void;
    pub extern fn uiDateTimePickerSetTime(d: *DateTimePicker, time: *const struct_tm) void;
    pub extern fn uiDateTimePickerOnChanged(d: *DateTimePicker, f: ?*const fn (?*DateTimePicker, ?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;
    pub extern fn uiNewDateTimePicker() ?*DateTimePicker;
    pub extern fn uiNewDatePicker() ?*DateTimePicker;
    pub extern fn uiNewTimePicker() ?*DateTimePicker;

    pub extern fn uiMultilineEntryText(e: *MultilineEntry) [*:0]const u8;
    pub extern fn uiMultilineEntrySetText(e: *MultilineEntry, text: [*:0]const u8) void;
    pub extern fn uiMultilineEntryAppend(e: *MultilineEntry, text: [*:0]const u8) void;
    pub extern fn uiMultilineEntryOnChanged(e: *MultilineEntry, f: ?*const fn (?*MultilineEntry, ?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;
    pub extern fn uiMultilineEntryReadOnly(e: *MultilineEntry) c_int;
    pub extern fn uiMultilineEntrySetReadOnly(e: *MultilineEntry, readonly: c_int) void;
    pub extern fn uiNewMultilineEntry() ?*MultilineEntry;
    pub extern fn uiNewNonWrappingMultilineEntry() ?*MultilineEntry;

    pub extern fn uiMenuItemEnable(m: *MenuItem) void;
    pub extern fn uiMenuItemDisable(m: *MenuItem) void;
    pub extern fn uiMenuItemOnClicked(m: *MenuItem, f: ?*const fn (?*MenuItem, ?*Window, ?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;
    pub extern fn uiMenuItemChecked(m: *MenuItem) c_int;
    pub extern fn uiMenuItemSetChecked(m: *MenuItem, checked: c_int) void;

    pub extern fn uiMenuAppendItem(m: *Menu, name: [*:0]const u8) ?*MenuItem;
    pub extern fn uiMenuAppendCheckItem(m: *Menu, name: [*:0]const u8) ?*MenuItem;
    pub extern fn uiMenuAppendQuitItem(m: *Menu) ?*MenuItem;
    pub extern fn uiMenuAppendPreferencesItem(m: *Menu) ?*MenuItem;
    pub extern fn uiMenuAppendAboutItem(m: *Menu) ?*MenuItem;
    pub extern fn uiMenuAppendSeparator(m: *Menu) void;
    pub extern fn uiNewMenu(name: [*:0]const u8) ?*Menu;

    pub extern fn uiOpenFile(parent: *Window) [*:0]const u8;
    pub extern fn uiOpenFileWithParams(parent: *Window, params: *FileDialogParams) [*:0]const u8;
    pub extern fn uiOpenFolder(parent: *Window) [*:0]const u8;
    pub extern fn uiOpenFolderWithParams(parent: *Window, params: *FileDialogParams) [*:0]const u8;
    pub extern fn uiSaveFile(parent: *Window) [*:0]const u8;
    pub extern fn uiSaveFileWithParams(parent: *Window, params: *FileDialogParams) [*:0]const u8;
    pub extern fn uiMsgBox(parent: *Window, title: [*:0]const u8, description: [*:0]const u8) void;
    pub extern fn uiMsgBoxError(parent: *Window, title: [*:0]const u8, description: [*:0]const u8) void;

    pub extern fn uiAreaSetSize(a: *Area, width: c_int, height: c_int) void;
    pub extern fn uiAreaQueueRedrawAll(a: *Area) void;
    pub extern fn uiAreaScrollTo(a: *Area, x: f64, y: f64, width: f64, height: f64) void;
    pub extern fn uiAreaBeginUserWindowMove(a: *Area) void;
    pub extern fn uiAreaBeginUserWindowResize(a: *Area, edge: Area.WindowResizeEdge) void;

    pub extern fn uiNewArea(ah: *Area.Handler) ?*Area;
    pub extern fn uiNewScrollingArea(ah: *Area.Handler, width: c_int, height: c_int) ?*Area;

    pub extern fn uiDrawStroke(c: *Area.Draw.Context, path: *Area.Draw.Path, b: *Area.Draw.Path.Brush, p: *Area.Draw.Path.StrokeParams) void;
    pub extern fn uiDrawFill(c: *Area.Draw.Context, path: *Area.Draw.Path, b: *Area.Draw.Path.Brush) void;
    pub extern fn uiDrawText(c: *Area.Draw.Context, tl: *Area.Draw.TextLayout, x: f64, y: f64) void;

    pub extern fn uiDrawMatrixSetIdentity(m: *Area.Draw.Matrix) void;
    pub extern fn uiDrawMatrixTranslate(m: *Area.Draw.Matrix, x: f64, y: f64) void;
    pub extern fn uiDrawMatrixScale(m: *Area.Draw.Matrix, xCenter: f64, yCenter: f64, x: f64, y: f64) void;
    pub extern fn uiDrawMatrixRotate(m: *Area.Draw.Matrix, x: f64, y: f64, amount: f64) void;
    pub extern fn uiDrawMatrixSkew(m: *Area.Draw.Matrix, x: f64, y: f64, xamount: f64, yamount: f64) void;
    pub extern fn uiDrawMatrixMultiply(dest: *Area.Draw.Matrix, src: *Area.Draw.Matrix) void;
    pub extern fn uiDrawMatrixInvertible(m: *Area.Draw.Matrix) c_int;
    pub extern fn uiDrawMatrixInvert(m: *Area.Draw.Matrix) c_int;
    pub extern fn uiDrawMatrixTransformPoint(m: *Area.Draw.Matrix, x: *f64, y: *f64) void;
    pub extern fn uiDrawMatrixTransformSize(m: *Area.Draw.Matrix, x: *f64, y: *f64) void;

    pub extern fn uiDrawNewPath(fillMode: Area.Draw.Path.FillMode) ?*Area.Draw.Path;
    pub extern fn uiDrawFreePath(p: *Area.Draw.Path) void;
    pub extern fn uiDrawPathNewFigure(p: *Area.Draw.Path, x: f64, y: f64) void;
    pub extern fn uiDrawPathNewFigureWithArc(p: *Area.Draw.Path, xCenter: f64, yCenter: f64, radius: f64, startAngle: f64, sweep: f64, negative: c_int) void;
    pub extern fn uiDrawPathLineTo(p: *Area.Draw.Path, x: f64, y: f64) void;
    pub extern fn uiDrawPathArcTo(p: *Area.Draw.Path, xCenter: f64, yCenter: f64, radius: f64, startAngle: f64, sweep: f64, negative: c_int) void;
    pub extern fn uiDrawPathBezierTo(p: *Area.Draw.Path, c1x: f64, c1y: f64, c2x: f64, c2y: f64, endX: f64, endY: f64) void;
    pub extern fn uiDrawPathCloseFigure(p: *Area.Draw.Path) void;
    pub extern fn uiDrawPathAddRectangle(p: *Area.Draw.Path, x: f64, y: f64, width: f64, height: f64) void;
    pub extern fn uiDrawPathEnded(p: *Area.Draw.Path) c_int;
    pub extern fn uiDrawPathEnd(p: *Area.Draw.Path) void;

    pub extern fn uiFreeAttribute(a: *Attribute) void;
    pub extern fn uiAttributeGetType(a: *const Attribute) Area.Draw.Path.Type;
    pub extern fn uiNewFamilyAttribute(family: [*:0]const u8) ?*Attribute;
    pub extern fn uiAttributeFamily(a: *const Attribute) [*:0]const u8;
    pub extern fn uiNewSizeAttribute(size: f64) ?*Attribute;
    pub extern fn uiAttributeSize(a: *const Attribute) f64;

    pub extern fn uiNewWeightAttribute(weight: Attribute.TextWeight) ?*Attribute;
    pub extern fn uiAttributeWeight(a: *const Attribute) Attribute.TextWeight;

    pub extern fn uiNewItalicAttribute(italic: Attribute.TextItalic) ?*Attribute;
    pub extern fn uiAttributeItalic(a: *const Attribute) Attribute.TextItalic;

    pub extern fn uiNewStretchAttribute(stretch: Attribute.TextStretch) ?*Attribute;
    pub extern fn uiAttributeStretch(a: *const Attribute) Attribute.TextStretch;
    pub extern fn uiNewColorAttribute(r: f64, g: f64, b: f64, a: f64) ?*Attribute;
    pub extern fn uiAttributeColor(a: *const Attribute, r: *f64, g: *f64, b: *f64, alpha: *f64) void;
    pub extern fn uiNewBackgroundAttribute(r: f64, g: f64, b: f64, a: f64) ?*Attribute;

    pub extern fn uiNewUnderlineAttribute(u: Attribute.Underline) ?*Attribute;
    pub extern fn uiAttributeUnderline(a: *const Attribute) Attribute.Underline;

    pub extern fn uiNewUnderlineColorAttribute(u: Attribute.UnderlineColor, r: f64, g: f64, b: f64, a: f64) ?*Attribute;
    pub extern fn uiAttributeUnderlineColor(a: *const Attribute, u: *Attribute.UnderlineColor, r: *f64, g: *f64, b: *f64, alpha: *f64) void;

    pub extern fn uiAttributeFeatures(a: *const Attribute) ?*const OpenTypeFeatures;

    pub extern fn uiNewOpenTypeFeatures() ?*OpenTypeFeatures;
    pub extern fn uiFreeOpenTypeFeatures(otf: *OpenTypeFeatures) void;
    pub extern fn uiOpenTypeFeaturesClone(otf: *const OpenTypeFeatures) ?*OpenTypeFeatures;
    pub extern fn uiOpenTypeFeaturesAdd(otf: *OpenTypeFeatures, a: u8, b: u8, c: u8, d: u8, value: u32) void;
    pub extern fn uiOpenTypeFeaturesRemove(otf: *OpenTypeFeatures, a: u8, b: u8, c: u8, d: u8) void;
    pub extern fn uiOpenTypeFeaturesGet(otf: *const OpenTypeFeatures, a: u8, b: u8, c: u8, d: u8, value: *u32) c_int;
    pub extern fn uiOpenTypeFeaturesForEach(otf: *const OpenTypeFeatures, f: OpenTypeFeatures.ForEachFunc, data: ?*anyopaque) void;
    pub extern fn uiNewFeaturesAttribute(otf: *const OpenTypeFeatures) ?*Attribute;

    pub extern fn uiNewAttributedString(initialString: [*:0]const u8) ?*AttributedString;
    pub extern fn uiFreeAttributedString(s: *AttributedString) void;
    pub extern fn uiAttributedStringString(s: *const AttributedString) [*:0]const u8;
    pub extern fn uiAttributedStringLen(s: *const AttributedString) usize;
    pub extern fn uiAttributedStringAppendUnattributed(s: *AttributedString, str: [*:0]const u8) void;
    pub extern fn uiAttributedStringInsertAtUnattributed(s: *AttributedString, str: [*:0]const u8, at: usize) void;
    pub extern fn uiAttributedStringDelete(s: *AttributedString, start: usize, end: usize) void;
    pub extern fn uiAttributedStringSetAttribute(s: *AttributedString, a: ?*Attribute, start: usize, end: usize) void;
    pub extern fn uiAttributedStringForEachAttribute(s: *const AttributedString, f: AttributedString.ForEachAttributeFunc, data: ?*anyopaque) void;
    pub extern fn uiAttributedStringNumGraphemes(s: *AttributedString) usize;
    pub extern fn uiAttributedStringByteIndexToGrapheme(s: *AttributedString, pos: usize) usize;
    pub extern fn uiAttributedStringGraphemeToByteIndex(s: *AttributedString, pos: usize) usize;

    pub extern fn uiLoadControlFont(f: *FontDescriptor) void;
    pub extern fn uiFreeFontDescriptor(desc: *FontDescriptor) void;

    pub extern fn uiDrawNewTextLayout(params: *Area.Draw.TextLayout.Params) ?*Area.Draw.TextLayout;

    pub extern fn uiDrawFreeTextLayout(tl: *Area.Draw.TextLayout) void;
    pub extern fn uiDrawTextLayoutExtents(tl: *Area.Draw.TextLayout, width: *f64, height: *f64) void;

    pub extern fn uiFontButtonFont(b: *FontButton, desc: *FontDescriptor) void;
    pub extern fn uiFontButtonOnChanged(b: *FontButton, f: ?*const fn (?*FontButton, ?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;
    pub extern fn uiNewFontButton() ?*FontButton;
    pub extern fn uiFreeFontButtonFont(desc: *FontDescriptor) void;

    pub extern fn uiColorButtonColor(b: *ColorButton, r: *f64, g: *f64, bl: *f64, a: *f64) void;
    pub extern fn uiColorButtonSetColor(b: *ColorButton, r: f64, g: f64, bl: f64, a: f64) void;
    pub extern fn uiColorButtonOnChanged(b: *ColorButton, f: ?*const fn (?*ColorButton, ?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;
    pub extern fn uiNewColorButton() ?*ColorButton;

    pub extern fn uiFormAppend(f: *Form, label: [*:0]const u8, c: *Control, stretchy: c_int) void;
    pub extern fn uiFormNumChildren(f: *Form) c_int;
    pub extern fn uiFormDelete(f: *Form, index: c_int) void;
    pub extern fn uiFormPadded(f: *Form) c_int;
    pub extern fn uiFormSetPadded(f: *Form, padded: c_int) void;
    pub extern fn uiNewForm() ?*Form;

    pub extern fn uiGridAppend(g: *Grid, c: ?*Control, left: c_int, top: c_int, xspan: c_int, yspan: c_int, hexpand: c_int, halign: Grid.Align, vexpand: c_int, valign: Grid.Align) void;
    pub extern fn uiGridInsertAt(g: *Grid, c: ?*Control, existing: *Control, at: Grid.At, xspan: c_int, yspan: c_int, hexpand: c_int, halign: Grid.Align, vexpand: c_int, valign: Grid.Align) void;
    pub extern fn uiGridPadded(g: *Grid) c_int;
    pub extern fn uiGridSetPadded(g: *Grid, padded: c_int) void;
    pub extern fn uiNewGrid() ?*Grid;

    pub extern fn uiNewImage(width: f64, height: f64) ?*Image;
    pub extern fn uiFreeImage(i: *Image) void;
    pub extern fn uiImageAppend(i: *Image, pixels: ?*anyopaque, pixelWidth: c_int, pixelHeight: c_int, byteStride: c_int) void;

    pub extern fn uiFreeTableValue(v: *Table.Value) void;

    pub extern fn uiTableValueGetType(v: *const Table.Value) Table.Value.Type;
    pub extern fn uiNewTableValueString(str: [*:0]const u8) ?*Table.Value;
    pub extern fn uiTableValueString(v: *const Table.Value) [*:0]const u8;
    pub extern fn uiNewTableValueImage(img: *Image) ?*Table.Value;
    pub extern fn uiTableValueImage(v: *const Table.Value) ?*Image;
    pub extern fn uiNewTableValueInt(i: c_int) ?*Table.Value;
    pub extern fn uiTableValueInt(v: *const Table.Value) c_int;
    pub extern fn uiNewTableValueColor(r: f64, g: f64, b: f64, a: f64) ?*Table.Value;
    pub extern fn uiTableValueColor(v: *const Table.Value, r: *f64, g: *f64, b: *f64, a: *f64) void;

    pub extern fn uiNewTableModel(mh: *Table.Model.Handler) ?*Table.Model;
    pub extern fn uiFreeTableModel(m: *Table.Model) void;
    pub extern fn uiTableModelRowInserted(m: ?*Table.Model, newIndex: c_int) void;
    pub extern fn uiTableModelRowChanged(m: ?*Table.Model, index: c_int) void;
    pub extern fn uiTableModelRowDeleted(m: ?*Table.Model, oldIndex: c_int) void;

    pub extern fn uiTableAppendTextColumn(t: *Table, name: [*:0]const u8, textModelColumn: c_int, textEditableModelColumn: c_int, textParams: *Table.TextColumnOptionalParams) void;
    pub extern fn uiTableAppendImageColumn(t: *Table, name: [*:0]const u8, imageModelColumn: c_int) void;
    pub extern fn uiTableAppendImageTextColumn(t: *Table, name: [*:0]const u8, imageModelColumn: c_int, textModelColumn: c_int, textEditableModelColumn: c_int, textParams: *Table.TextColumnOptionalParams) void;
    pub extern fn uiTableAppendCheckboxColumn(t: *Table, name: [*:0]const u8, checkboxModelColumn: c_int, checkboxEditableModelColumn: c_int) void;
    pub extern fn uiTableAppendCheckboxTextColumn(t: *Table, name: [*:0]const u8, checkboxModelColumn: c_int, checkboxEditableModelColumn: c_int, textModelColumn: c_int, textEditableModelColumn: c_int, textParams: *Table.TextColumnOptionalParams) void;
    pub extern fn uiTableAppendProgressBarColumn(t: *Table, name: [*:0]const u8, progressModelColumn: c_int) void;
    pub extern fn uiTableAppendButtonColumn(t: *Table, name: [*:0]const u8, buttonModelColumn: c_int, buttonClickableModelColumn: c_int) void;
    pub extern fn uiTableHeaderVisible(t: *Table) c_int;
    pub extern fn uiTableHeaderSetVisible(t: *Table, visible: c_int) void;
    pub extern fn uiNewTable(params: *Table.Params) ?*Table;
    pub extern fn uiTableOnRowClicked(t: *Table, f: ?*const fn (?*Table, c_int, ?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;
    pub extern fn uiTableOnRowDoubleClicked(t: *Table, f: ?*const fn (?*Table, c_int, ?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;
    pub extern fn uiTableHeaderSetSortIndicator(t: *Table, column: c_int, indicator: Table.Value.SortIndicator) void;
    pub extern fn uiTableHeaderSortIndicator(t: *Table, column: c_int) Table.Value.SortIndicator;
    pub extern fn uiTableHeaderOnClicked(t: *Table, f: ?*const fn (?*Table, c_int, ?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;
    pub extern fn uiTableColumnWidth(t: *Table, column: c_int) c_int;
    pub extern fn uiTableColumnSetWidth(t: *Table, column: c_int, width: c_int) void;

    pub extern fn uiTableGetSelectionMode(t: *Table) Table.SelectionMode;
    pub extern fn uiTableSetSelectionMode(t: *Table, mode: Table.SelectionMode) void;
    pub extern fn uiTableOnSelectionChanged(t: *Table, f: ?*const fn (?*Table, ?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;

    pub extern fn uiTableGetSelection(t: *Table) ?*Table.Selection;
    pub extern fn uiTableSetSelection(t: *Table, sel: *Table.Selection) void;
    pub extern fn uiFreeTableSelection(s: *Table.Selection) void;
};
