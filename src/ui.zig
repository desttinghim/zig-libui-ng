//! # Libui-ng Zig Bindings
//!
//! Bindings to make using libui-ng from zig more pleasant.
//!
//! ## API
//! Function names are meant to match the function names in libui with the `ui` prefix
//! removed. Extern functions are exported under the namespace of the control they are
//! for.

const ui = @This();

pub fn Init(options: *InitData) !void {
    const err = uiInit(&options.options);
    if (err == null) return;
    options.error_string = err;
    return InitError.Other;
}

pub const Uninit = uiUninit;
pub const Main = uiMain;
pub const MainSteps = uiMainSteps;
pub const MainStep = uiMainStep;
pub const Quit = uiQuit;
pub const FreeText = uiFreeText;

/// Tagged union, each tag corresponds to a callback.
pub const ErrorContext = union(enum) {
    QueueMain,
    Timer,
    OnShouldQuit,
    WindowOnPositionChanged: ?*Window,
    WindowOnContentSizeChanged: ?*Window,
    WindowOnClosing: ?*Window,
    WindowOnFocusChanged: ?*Window,
    ButtonOnClicked: ?*Button,
    CheckboxOnToggled: ?*Checkbox,
    EntryOnChanged: ?*Entry,
    SpinboxOnChanged: ?*Spinbox,
    SliderOnChanged: ?*Slider,
    SliderOnReleased: ?*Slider,
    ComboboxOnSelected: ?*Combobox,
    EditableComboboxOnChanged: ?*EditableCombobox,
    RadioButtonsOnSelected: ?*RadioButtons,
    DateTimePickerOnChanged: ?*DateTimePicker,
    MultilineEntryOnChanged: ?*MultilineEntry,
    MenuItemOnClicked: ?*MenuItem,
    FontButtonOnChanged: ?*FontButton,
    ColorButtonOnChanged: ?*ColorButton,
    TableOnRowClicked: ?*Table,
    TableOnRowDoubleClicked: ?*Table,
    TableOnSelectionChanged: ?*Table,
};

pub const Error = error{ LibUIPassedNullPointer, LibUINullUserdata };

/// Checks the root module for a function called `OnError`. If the developer
/// does not define an error handler, `OnError` will be used by default.
/// OnError is used by callbacks (functions with a name like On*) to handle error
/// values returned by the user.
///
/// An error handler function should have a signature of `*const fn(ErrorContext, ?*anyopaque, E) void`,
/// where E is an error set of all possible errors used by your program.
pub const error_handler = if (@hasDecl(root, "OnError")) root.OnError else OnError;

pub fn OnError(context: ErrorContext, userdata: ?*anyopaque, err: anyerror) void {
    @setCold(true);
    var buffer: [4096]u8 = undefined;
    const message = std.fmt.bufPrint(&buffer, "Error while executing callback - [Context] {} [User Data] {*} [Error] {}", .{ context, userdata, err }) catch buffer[0..];
    @panic(message);
}

/// Queue a function to be called in a loop by `ui.Main`.
pub fn QueueMain(comptime T: type, comptime E: type, comptime callback: *const fn (?*T) E!void, data: ?*T) void {
    const cb = struct {
        fn cb(t_opt: ?*anyopaque) callconv(.C) void {
            @call(.auto, callback, .{@as(?*T, @ptrCast(@alignCast(t_opt)))}) catch |err| error_handler(.QueueMain, t_opt, err);
        }
    }.cb;
    uiQueueMain(cb, data);
}

/// Queue a function to be called after `milliseconds`. Do not rely on this if you need precise
/// time tracking.
pub fn Timer(comptime T: type, comptime E: type, milliseconds: c_int, comptime callback: *const fn (?*T) E!TimerAction, data: ?*T) void {
    const cb = struct {
        fn cb(t_opt: ?*anyopaque) callconv(.C) TimerAction {
            return @call(.auto, callback, .{@as(?*T, @ptrCast(@alignCast(t_opt)))}) catch |err| {
                error_handler(.Timer, t_opt, err);
                return TimerAction.disarm;
            };
        }
    }.cb;
    uiTimer(milliseconds, cb, data);
}

/// Set a function to be called when the user attempts to quit.
/// Return a value of `QuitAction.should_quit` to allow the user to close the window.
/// Return a value of `QuitAction.should_not_quit` to prevent the user from closing the window.
/// `QuitAciton.should_not_quit` should only be used for special cases, like asking the user
/// if they want to save their work before exiting.
pub fn OnShouldQuit(comptime T: type, comptime E: type, comptime callback: *const fn (?*T) E!QuitAction, data: ?*T) void {
    const cb = struct {
        fn cb(t_opt: ?*anyopaque) callconv(.C) QuitAction {
            return @call(.auto, callback, .{@as(?*T, @ptrCast(@alignCast(t_opt)))}) catch |err| {
                error_handler(.OnShouldQuit, t_opt, err);
                return 1;
            };
        }
    }.cb;
    uiOnShouldQuit(cb, data);
}

pub const InitData = struct {
    options: InitOptions,
    error_string: ?[*:0]const u8 = null,

    pub fn get_error(data: *const InitData) [*:0]const u8 {
        std.debug.assert(data.error_string != null);
        return data.error_string.?;
    }

    pub fn free_error(data: *InitData) void {
        const string = data.error_string orelse return;
        uiFreeInitError(string);
    }
};

pub const InitError = error{
    /// This error has not been encoded into a Zig error - check the value
    /// of InitOptions.error_string to check the message returned by libui
    Other,
};

pub const MainStepWait = enum(c_int) {
    blocking = 1,
    nonblocking = 0,
};
pub const MainStepStatus = enum(c_int) {
    finished = 0,
    running = 1,
};

pub const TimerAction = enum(c_int) {
    disarm = 0,
    rearm = 1,
};

pub const QuitAction = enum(c_int) {
    should_not_quit = 0,
    should_quit = 1,
};

pub const ForEach = enum(c_int) {
    Continue = 0,
    Stop = 1,
};

pub const InitOptions = extern struct {
    Size: usize,
};

pub const Stretchy = enum(c_int) {
    stretch = 1,
    dont_stretch = 0,
};

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
pub extern fn uiFreeText(text: [*:0]const u8) void;

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

    pub const Destroy = uiControlDestroy;
    pub const Handle = uiControlHandle;
    pub const Parent = uiControlParent;
    pub const SetParent = uiControlSetParent;
    pub const Show = uiControlShow;
    pub const Hide = uiControlHide;
    pub const Enable = uiControlEnable;
    pub const Disable = uiControlDisable;
    pub const Free = uiFreeControl;
    pub const VerifySetParent = uiControlVerifySetParent;

    pub fn Toplevel(c: *Control) bool {
        return uiControlToplevel(c) == 1;
    }
    pub fn Visible(c: *Control) bool {
        return uiControlVisible(c) == 1;
    }
    pub fn Enabled(c: *Control) bool {
        return uiControlEnabled(c) == 1;
    }
    pub fn Alloc(n: usize, OSsig: u32, typesig: u32, typenamestr: [*:0]const u8) ?[*]Control {
        return uiAllocControl(n, OSsig, typesig, typenamestr);
    }
    pub fn EnabledToUser(c: *Control) bool {
        return uiControlEnabledToUser(c) == 1;
    }
};

/// Window is a top-level `Control` that contains all other `Control`s. A Window is needed
/// to display anything to the screen. Dialog boxes require a parent Window.
pub const Window = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }

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

    pub const Title = uiWindowTitle;
    pub const SetTitle = uiWindowSetTitle;
    pub const SetChild = uiWindowSetChild;

    const Point = struct {
        x: c_int,
        y: c_int,
    };
    pub fn Position(w: *Window) Point {
        var point: Point = .{ .x = 0, .y = 0 };
        uiWindowPosition(w, &point.x, &point.y);
        return point;
    }

    pub fn SetPosition(w: *Window, x: c_int, y: c_int) void {
        uiWindowSetPosition(w, x, y);
    }

    pub const Size = struct {
        width: c_int,
        height: c_int,
    };
    pub fn ContentSize(w: *Window) Size {
        var size: Size = .{ .width = 0, .height = 0 };
        uiWindowContentSize(w, &size.width, &size.height);
        return size;
    }

    pub fn SetContentSize(w: *Window, width: c_int, height: c_int) void {
        uiWindowSetContentSize(w, width, height);
    }

    pub fn Fullscreen(w: *Window) bool {
        return uiWindowFullscreen(w) == 1;
    }

    pub fn SetFullscreen(w: *Window, fullscreen: bool) void {
        uiWindowSetFullscreen(w, @intFromBool(fullscreen));
    }

    pub fn Focused(w: *Window) bool {
        return uiWindowFocused(w) == 1;
    }

    pub fn Borderless(w: *Window) bool {
        return uiWindowBorderless(w) == 1;
    }

    pub fn SetBorderless(w: *Window, borderless: bool) void {
        uiWindowSetBorderless(w, @intFromBool(borderless));
    }

    pub fn Margined(w: *Window) bool {
        uiWindowMargined(w) == 1;
    }

    pub fn SetMargined(w: *Window, margined: bool) void {
        uiWindowSetMargined(w, @intFromBool(margined));
    }

    pub fn Resizeable(w: *Window) bool {
        return uiWindowResizeable(w);
    }

    pub fn SetResizeable(w: *Window, resizeable: bool) void {
        uiWindowSetResizeable(w, @intFromBool(resizeable));
    }

    const HasMenubar = enum(c_int) {
        hide_menubar = 0,
        show_menubar = 1,
    };
    pub fn New(title: [*:0]const u8, width: c_int, height: c_int, hasMenubar: HasMenubar) !*Window {
        const new_window = uiNewWindow(title, width, height, @intFromEnum(hasMenubar));
        if (new_window == null) return error.InitWindow;
        return new_window.?;
    }

    pub fn OnPositionChanged(window: *Window, comptime T: type, comptime E: type, comptime f: *const fn (*Window, ?*T) E!void, userdata: ?*T) void {
        const callback = struct {
            fn callback(window_opt: ?*Window, t_opt: ?*anyopaque) callconv(.C) void {
                const err_ctx = ErrorContext{ .WindowOnPositionChanged = window_opt };
                const w = window_opt orelse return error_handler(err_ctx, t_opt, error.LibUIPassedNullPointer);
                f(w, @as(?*T, @ptrCast(@alignCast(t_opt)))) catch |err| error_handler(err_ctx, t_opt, err);
            }
        }.callback;
        uiWindowOnPositionChanged(window, callback, userdata);
    }

    pub fn OnContentSizeChanged(window: *Window, comptime T: type, comptime E: type, comptime f: *const fn (*Window, ?*T) E!void, userdata: ?*T) void {
        const callback = struct {
            fn callback(window_opt: ?*Window, t_opt: ?*anyopaque) callconv(.C) void {
                const err_ctx = ErrorContext{ .WindowOnContentSizeChanged = window_opt };
                const w = window_opt orelse return error_handler(err_ctx, t_opt, error.LibUIPassedNullPointer);
                f(w, @as(?*T, @ptrCast(@alignCast(t_opt)))) catch |err| error_handler(err_ctx, t_opt, err);
            }
        }.callback;
        uiWindowOnContentSizeChanged(window, callback, userdata);
    }

    pub const ClosingAction = enum(c_int) {
        should_not_close = 0,
        should_close = 1,
    };
    pub fn OnClosing(window: *Window, comptime T: type, comptime E: type, comptime f: *const fn (*Window, ?*T) E!ClosingAction, userdata: ?*T) void {
        const callback = struct {
            fn callback(window_opt: ?*Window, t_opt: ?*anyopaque) callconv(.C) ClosingAction {
                const err_ctx = ErrorContext{ .WindowOnClosing = window_opt };
                const w = window_opt orelse {
                    error_handler(err_ctx, t_opt, error.LibUIPassedNullPointer);
                    return .should_close;
                };
                return f(w, @as(?*T, @ptrCast(@alignCast(t_opt)))) catch |err| {
                    error_handler(err_ctx, t_opt, err);
                    return .should_close;
                };
            }
        }.callback;
        uiWindowOnClosing(window, callback, userdata);
    }

    pub fn OnFocusChanged(window: *Window, comptime T: type, comptime f: *const fn (*Window, ?*T) void, userdata: ?*T) void {
        const callback = struct {
            fn callback(window_opt: ?*Window, t_opt: ?*anyopaque) callconv(.C) void {
                const err_ctx = ErrorContext{ .WindowOnFocusChanged = window_opt };
                const w = window_opt orelse return error_handler(err_ctx, t_opt, error.LibUIPassedNullPointer);
                f(w, @as(?*T, @ptrCast(@alignCast(t_opt)))) catch |err| error_handler(err_ctx, t_opt, err);
            }
        }.callback;
        uiWindowOnFocusChanged(window, callback, userdata);
    }

    // Dialog boxes
    pub extern fn uiOpenFile(parent: *Window) ?[*:0]const u8;
    pub extern fn uiOpenFileWithParams(parent: *Window, params: *FileDialogParams) ?[*:0]const u8;
    pub extern fn uiOpenFolder(parent: *Window) ?[*:0]const u8;
    pub extern fn uiOpenFolderWithParams(parent: *Window, params: *FileDialogParams) ?[*:0]const u8;
    pub extern fn uiSaveFile(parent: *Window) ?[*:0]const u8;
    pub extern fn uiSaveFileWithParams(parent: *Window, params: *FileDialogParams) ?[*:0]const u8;
    pub extern fn uiMsgBox(parent: *Window, title: [*:0]const u8, description: [*:0]const u8) void;
    pub extern fn uiMsgBoxError(parent: *Window, title: [*:0]const u8, description: [*:0]const u8) void;

    pub const OpenFile = uiOpenFile;
    pub const OpenFileWithParams = uiOpenFileWithParams;
    pub const OpenFolder = uiOpenFolder;
    pub const SaveFile = uiSaveFile;
    pub const SaveFileWithParams = uiSaveFileWithParams;
    pub const MsgBox = uiMsgBox;
    pub const MsgBoxError = uiMsgBoxError;
};

/// `Button` is a clickable control that can run a callback when clicked.
pub const Button = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }

    pub extern fn uiButtonText(b: *Button) [*:0]const u8;
    pub extern fn uiButtonSetText(b: *Button, text: [*:0]const u8) void;
    pub extern fn uiButtonOnClicked(b: *Button, f: ?*const fn (*Button, ?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;
    pub extern fn uiNewButton(text: [*:0]const u8) ?*Button;

    pub const Text = uiButtonText;
    pub const SetText = uiButtonSetText;

    pub fn OnClicked(self: *Self, comptime T: type, comptime E: type, comptime f: *const fn (*Self, ?*T) E!void, userdata: ?*T) void {
        const callback = struct {
            fn callback(button_opt: ?*Self, t_opt: ?*anyopaque) callconv(.C) void {
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
        return uiBoxPadded(b) == 1;
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

/// `Checkbox` is a clickable control that toggles between an off and on state.
pub const Checkbox = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }

    pub extern fn uiCheckboxText(c: *Checkbox) [*:0]u8;
    pub extern fn uiCheckboxSetText(c: *Checkbox, text: [*:0]const u8) void;
    pub extern fn uiCheckboxOnToggled(c: *Checkbox, f: ?*const fn (*Checkbox, ?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;
    pub extern fn uiCheckboxChecked(c: *Checkbox) c_int;
    pub extern fn uiCheckboxSetChecked(c: *Checkbox, checked: c_int) void;
    pub extern fn uiNewCheckbox(text: [*:0]const u8) ?*Checkbox;

    pub const Text = uiCheckboxText;
    pub const SetText = uiCheckboxText;

    pub fn OnToggled(self: *Self, comptime T: type, f: *const fn (*Self, ?*T) void, userdata: ?*T) void {
        const callback = struct {
            fn callback(self_opt: ?*Self, t_opt: ?*anyopaque) callconv(.C) void {
                const err_ctx = ErrorContext{ .CheckboxOnToggled = self_opt };
                const s = self_opt orelse return error_handler(err_ctx, t_opt, error.LibUIPassedNullPointer);
                f(s, @as(?*T, @ptrCast(@alignCast(t_opt)))) catch |err| error_handler(err_ctx, t_opt, err);
            }
        }.callback;
        uiCheckboxOnToggled(self, callback, userdata);
    }

    pub fn Checked(c: *Checkbox) bool {
        return uiCheckboxChecked(c) == 1;
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

/// `Entry` is a single line text entry control. See MultilineEntry for a more advanced
/// text entry control.
pub const Entry = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }

    pub extern fn uiEntryText(e: *Entry) [*:0]u8;
    pub extern fn uiEntrySetText(e: *Entry, text: [*:0]const u8) void;
    pub extern fn uiEntryOnChanged(e: *Entry, f: ?*const fn (*Entry, ?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;
    pub extern fn uiEntryReadOnly(e: *Entry) c_int;
    pub extern fn uiEntrySetReadOnly(e: *Entry, readonly: c_int) void;
    pub extern fn uiNewEntry() ?*Entry;
    pub extern fn uiNewPasswordEntry() ?*Entry;
    pub extern fn uiNewSearchEntry() ?*Entry;

    pub const Text = uiEntryText;
    pub const SetText = uiEntrySetText;
    pub fn OnChanged(self: *Self, comptime T: type, comptime E: type, comptime f: *const fn (*Self, ?*T) E!void, userdata: ?*T) void {
        const callback = struct {
            fn callback(self_opt: ?*Self, t_opt: ?*anyopaque) callconv(.C) void {
                const err_ctx = ErrorContext{ .EntryOnChanged = self_opt };
                const s = self_opt orelse return error_handler(err_ctx, t_opt, error.LibUIPassedNullPointer);
                f(s, @as(?*T, @ptrCast(@alignCast(t_opt)))) catch |err| error_handler(err_ctx, t_opt, err);
            }
        }.callback;
        uiEntryOnChanged(self, callback, userdata);
    }

    pub fn ReadOnly(e: *Entry) bool {
        return uiEntryReadOnly(e) == 1;
    }
    pub fn SetReadOnly(e: *Entry, readonly: c_int) void {
        return uiEntrySetReadOnly(e, @intFromBool(readonly));
    }
    pub const Type = enum {
        Entry,
        Password,
        Search,
    };
    pub fn New(t: Type) !*Entry {
        const new_entry = switch (t) {
            .Entry => uiNewEntry(),
            .Password => uiNewPasswordEntry(),
            .Search => uiNewSearchEntry(),
        };
        if (new_entry == null) return error.InitEntry;
        return new_entry.?;
    }
};

/// Label is a control for displaying read-only text.
pub const Label = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }

    pub extern fn uiLabelText(l: *Label) [*:0]u8;
    pub extern fn uiLabelSetText(l: *Label, text: [*:0]const u8) void;
    pub extern fn uiNewLabel(text: [*:0]const u8) ?*Label;

    pub const Text = uiLabelText;
    pub const SetText = uiLabelSetText;
    pub fn New(text: [*:0]const u8) !*Label {
        return uiNewLabel(text) orelse error.InitLabel;
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
        return uiTabMargined(t, index) == 1;
    }
    pub fn SetMargined(t: *Tab, index: c_int, margined: bool) void {
        return uiTabSetMargined(t, index, @intFromBool(margined));
    }
    pub fn New() !*Tab {
        return uiNewTab() orelse error.InitTab;
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
        return uiGroupMargined(g) == 1;
    }
    pub fn SetMargined(g: *Group, margined: bool) void {
        uiGroupSetMargined(g, margined);
    }
    pub fn New(title: [*:0]const u8) !*Group {
        return uiNewGroup(title) orelse error.InitGroup;
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
    pub extern fn uiSpinboxOnChanged(s: *Spinbox, f: ?*const fn (?*Spinbox, ?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;
    pub extern fn uiNewSpinbox(min: c_int, max: c_int) ?*Spinbox;
    pub extern fn uiNewSpinboxDouble(min: f64, max: f64, precision: c_int) ?*Spinbox;

    pub const Value = uiSpinboxValue;
    pub const ValueDouble = uiSpinboxValueDouble;
    pub const SetValue = uiSpinboxSetValue;
    pub const SetValueDouble = uiSpinboxSetValueDouble;
    pub const ValueText = uiSpinboxValueText;

    pub fn OnChanged(self: *Self, comptime T: type, comptime E: type, comptime f: *const fn (*Self, ?*T) E!void, userdata: ?*T) void {
        const callback = struct {
            fn callback(self_opt: ?*Self, t_opt: ?*anyopaque) callconv(.C) void {
                const err_ctx = ErrorContext{ .SpinboxOnChanged = self_opt };
                const s = self_opt orelse return error_handler(err_ctx, t_opt, error.LibUIPassedNullPointer);
                f(s, @as(?*T, @ptrCast(@alignCast(t_opt)))) catch |err| error_handler(err_ctx, t_opt, err);
            }
        }.callback;
        uiSpinboxOnChanged(self, callback, userdata);
    }

    pub const Type = union(enum) {
        Integer: struct { min: c_int, max: c_int },
        Double: struct { min: f64, max: f64, precision: c_int },
    };
    pub fn New(t: Type) !*Spinbox {
        return switch (t) {
            .Integer => |int| uiNewSpinbox(int.min, int.max),
            .Double => |dbl| uiNewSpinboxDouble(dbl.min, dbl.max, dbl.precision),
        } orelse error.InitSpinbox;
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
    pub extern fn uiSliderOnChanged(s: *Slider, f: ?*const fn (*Slider, ?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;
    pub extern fn uiSliderOnReleased(s: *Slider, f: ?*const fn (*Slider, ?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;
    pub extern fn uiSliderSetRange(s: *Slider, min: c_int, max: c_int) void;
    pub extern fn uiNewSlider(min: c_int, max: c_int) ?*Slider;

    pub const Value = uiSliderValue;
    pub const SetValue = uiSliderSetValue;
    pub fn HasToolTip(s: *Slider) bool {
        return uiSliderHasToolTip(s) == 1;
    }
    pub fn SetHasToolTip(s: *Slider, hasToolTip: bool) void {
        uiSliderSetHasToolTip(s, @intFromBool(hasToolTip));
    }
    pub fn OnChanged(self: *Self, comptime T: type, comptime E: type, comptime f: *const fn (*Self, ?*T) E!void, userdata: ?*T) void {
        const callback = struct {
            fn callback(self_opt: ?*Self, t_opt: ?*anyopaque) callconv(.C) void {
                const err_ctx = ErrorContext{ .SliderOnChanged = self_opt };
                const s = self_opt orelse return error_handler(err_ctx, t_opt, error.LibUIPassedNullPointer);
                f(s, @as(?*T, @ptrCast(@alignCast(t_opt)))) catch |err| error_handler(err_ctx, t_opt, err);
            }
        }.callback;
        uiSliderOnChanged(self, callback, userdata);
    }
    pub fn OnReleased(self: *Self, comptime T: type, comptime E: type, comptime f: *const fn (*Self, ?*T) E!void, userdata: ?*T) void {
        const callback = struct {
            fn callback(self_opt: ?*Self, t_opt: ?*anyopaque) callconv(.C) void {
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

/// ProgressBar is a control that is used to indicate progress.
pub const ProgressBar = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }

    pub extern fn uiProgressBarValue(p: *ProgressBar) c_int;
    pub extern fn uiProgressBarSetValue(p: *ProgressBar, n: c_int) void;
    pub extern fn uiNewProgressBar() ?*ProgressBar;

    pub const Value = uiProgressBarValue;
    pub const SetValue = uiProgressBarSetValue;
    pub fn New() !*ProgressBar {
        return uiNewProgressBar() orelse error.InitProgressBar;
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

    pub const Type = enum {
        Horizontal,
        Vertical,
    };
    pub fn New(t: Type) !*Separator {
        return switch (t) {
            .Horizontal => uiNewHorizontalSeparator(),
            .Vertical => uiNewVerticalSeparator(),
        } orelse error.InitSeparator;
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
    pub extern fn uiComboboxOnSelected(c: *Combobox, f: ?*const fn (?*Combobox, ?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;
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
            fn callback(self_opt: ?*Self, t_opt: ?*anyopaque) callconv(.C) void {
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

/// EditableCombobox is a control that allows users to select a value from a list or enter
/// a custom value if it is not present.
pub const EditableCombobox = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }

    pub extern fn uiEditableComboboxAppend(c: *EditableCombobox, text: [*:0]const u8) void;
    pub extern fn uiEditableComboboxText(c: *EditableCombobox) [*:0]const u8;
    pub extern fn uiEditableComboboxSetText(c: *EditableCombobox, text: [*:0]const u8) void;
    pub extern fn uiEditableComboboxOnChanged(c: *EditableCombobox, f: ?*const fn (?*EditableCombobox, ?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;
    pub extern fn uiNewEditableCombobox() ?*EditableCombobox;

    pub const Append = uiEditableComboboxAppend;
    pub const Text = uiEditableComboboxText;
    pub const SetText = uiEditableComboboxSetText;
    pub fn OnChanged(self: *Self, comptime T: type, comptime E: type, comptime f: *const fn (*Self, ?*T) E!void, userdata: ?*T) void {
        const callback = struct {
            fn callback(self_opt: ?*Self, t_opt: ?*anyopaque) callconv(.C) void {
                const err_ctx = ErrorContext{ .EditableComboboxOnChanged = self_opt };
                const s = self_opt orelse return error_handler(err_ctx, t_opt, error.LibUIPassedNullPointer);
                f(s, @as(?*T, @ptrCast(@alignCast(t_opt)))) catch |err| error_handler(err_ctx, t_opt, err);
            }
        }.callback;
        uiEditableComboboxOnChanged(self, callback, userdata);
    }
    pub fn New() !*EditableCombobox {
        return uiNewEditableCombobox() orelse error.InitEditableCombobox;
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
    pub extern fn uiRadioButtonsOnSelected(r: *RadioButtons, f: ?*const fn (?*RadioButtons, ?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;
    pub extern fn uiNewRadioButtons() ?*RadioButtons;

    pub const Append = uiRadioButtonsAppend;
    pub const Selected = uiRadioButtonsSelected;
    pub const SetSelected = uiRadioButtonsSetSelected;
    pub fn OnSelected(self: *Self, comptime T: type, comptime E: type, comptime f: *const fn (*Self, ?*T) E!void, userdata: ?*T) void {
        const callback = struct {
            fn callback(self_opt: ?*Self, t_opt: ?*anyopaque) callconv(.C) void {
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
    pub extern fn uiDateTimePickerOnChanged(d: *DateTimePicker, f: ?*const fn (?*DateTimePicker, ?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;
    pub extern fn uiNewDateTimePicker() ?*DateTimePicker;
    pub extern fn uiNewDatePicker() ?*DateTimePicker;
    pub extern fn uiNewTimePicker() ?*DateTimePicker;

    // pub const Time = uiDateTimePickerTime;
    pub fn Time(d: *DateTimePicker) struct_tm {
        var tm: struct_tm = undefined;
        d.uiDateTimePickerTime(&tm);
        return tm;
    }
    pub const SetTime = uiDateTimePickerSetTime;
    pub fn OnChanged(self: *Self, comptime T: type, comptime E: type, comptime f: *const fn (*Self, ?*T) E!void, userdata: ?*T) void {
        const callback = struct {
            fn callback(self_opt: ?*Self, t_opt: ?*anyopaque) callconv(.C) void {
                const err_ctx = ErrorContext{ .DateTimePickerOnChanged = self_opt };
                const s = self_opt orelse return error_handler(err_ctx, t_opt, error.LibUIPassedNullPointer);
                f(s, @as(?*T, @ptrCast(@alignCast(t_opt)))) catch |err| error_handler(err_ctx, t_opt, err);
            }
        }.callback;
        uiDateTimePickerOnChanged(self, callback, userdata);
    }
    pub const Type = enum {
        DateTime,
        Date,
        Time,
    };
    pub fn New(t: Type) !*DateTimePicker {
        return switch (t) {
            .DateTime => uiNewDateTimePicker(),
            .Date => uiNewDatePicker(),
            .Time => uiNewTimePicker(),
        } orelse error.InitDateTimePicker;
    }
};

/// MultilineEntry is a control that allows entering multiple lines of text.
pub const MultilineEntry = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }

    pub extern fn uiMultilineEntryText(e: *MultilineEntry) [*:0]const u8;
    pub extern fn uiMultilineEntrySetText(e: *MultilineEntry, text: [*:0]const u8) void;
    pub extern fn uiMultilineEntryAppend(e: *MultilineEntry, text: [*:0]const u8) void;
    pub extern fn uiMultilineEntryOnChanged(e: *MultilineEntry, f: ?*const fn (?*MultilineEntry, ?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;
    pub extern fn uiMultilineEntryReadOnly(e: *MultilineEntry) c_int;
    pub extern fn uiMultilineEntrySetReadOnly(e: *MultilineEntry, readonly: c_int) void;
    pub extern fn uiNewMultilineEntry() ?*MultilineEntry;
    pub extern fn uiNewNonWrappingMultilineEntry() ?*MultilineEntry;

    pub const Text = uiMultilineEntryText;
    pub const SetText = uiMultilineEntrySetText;
    pub const Append = uiMultilineEntryAppend;
    pub fn OnChanged(self: *Self, comptime T: type, comptime E: type, comptime f: *const fn (*Self, ?*T) E!void, userdata: ?*T) void {
        const callback = struct {
            fn callback(self_opt: ?*Self, t_opt: ?*anyopaque) callconv(.C) void {
                const err_ctx = ErrorContext{ .MultilineEntryOnChanged = self_opt };
                const s = self_opt orelse return error_handler(err_ctx, t_opt, error.LibUIPassedNullPointer);
                f(s, @as(?*T, @ptrCast(@alignCast(t_opt)))) catch |err| error_handler(err_ctx, t_opt, err);
            }
        }.callback;
        uiMultilineEntryOnChanged(self, callback, userdata);
    }
    pub fn ReadOnly(e: *MultilineEntry) bool {
        return uiMultilineEntryReadOnly(e) == 1;
    }
    pub fn SetReadOnly(e: *MultilineEntry, readonly: bool) void {
        return uiMultilineEntrySetReadOnly(e, @intFromBool(readonly));
    }
    pub const Type = enum {
        Wrapping,
        NonWrapping,
    };
    pub fn New(t: Type) !*MultilineEntry {
        return switch (t) {
            .Wrapping => uiNewMultilineEntry(),
            .NonWrapping => uiNewNonWrappingMultilineEntry(),
        } orelse error.InitMultilineEntry;
    }
};

/// MenuItem is a control for a single item within a `Menu`. Must be created using one of
/// the `Append` functions on `Menu`.
pub const MenuItem = opaque {
    pub extern fn uiMenuItemEnable(m: *MenuItem) void;
    pub extern fn uiMenuItemDisable(m: *MenuItem) void;
    pub extern fn uiMenuItemOnClicked(m: *MenuItem, f: ?*const fn (?*MenuItem, ?*Window, ?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;
    pub extern fn uiMenuItemChecked(m: *MenuItem) c_int;
    pub extern fn uiMenuItemSetChecked(m: *MenuItem, checked: c_int) void;

    pub const Enable = uiMenuItemEnable;
    pub const Disable = uiMenuItemDisable;
    pub const Self = @This();
    pub fn OnClicked(self: *Self, comptime T: type, comptime E: type, comptime f: *const fn (*Self, ?*T) E!void, userdata: ?*T) void {
        const callback = struct {
            fn callback(self_opt: ?*Self, t_opt: ?*anyopaque) callconv(.C) void {
                const err_ctx = ErrorContext{ .MenuItemOnClicked = self_opt };
                const s = self_opt orelse return error_handler(err_ctx, t_opt, error.LibUIPassedNullPointer);
                f(s, @as(?*T, @ptrCast(@alignCast(t_opt)))) catch |err| error_handler(err_ctx, t_opt, err);
            }
        }.callback;
        uiMenuItemOnClicked(self, callback, userdata);
    }
    pub fn Checked(m: *MenuItem) bool {
        return uiMenuItemChecked(m) == 1;
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

/// Structure to pass to `Window.OpenFileWithParams`
pub const FileDialogParams = extern struct {
    pub const Filter = extern struct {
        name: [*:0]const u8,
        patternCount: usize,
        patterns: *[*:0]const u8,
    };
    defaultPath: ?[*:0]const u8,
    defaultName: ?[*:0]const u8,
    filterCount: usize,
    filters: ?[*]const Filter,
};

/// Area is a control that allows drawing to a canvas using geometric shapes and lines.
pub const Area = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }

    pub extern fn uiAreaSetSize(a: *Area, width: c_int, height: c_int) void;
    pub extern fn uiAreaQueueRedrawAll(a: *Area) void;
    pub extern fn uiAreaScrollTo(a: *Area, x: f64, y: f64, width: f64, height: f64) void;
    pub extern fn uiAreaBeginUserWindowMove(a: *Area) void;
    pub extern fn uiAreaBeginUserWindowResize(a: *Area, edge: Area.WindowResizeEdge) void;

    pub const SetSize = uiAreaSetSize;
    pub const QueueRedrawAll = uiAreaQueueRedrawAll;
    pub const ScrollTo = uiAreaScrollTo;
    pub const BeginUserWindowMove = uiAreaBeginUserWindowMove;
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
    pub const BeginUserWindowResize = uiAreaBeginUserWindowResize;

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

        pub extern fn uiNewArea(ah: *Area.Handler) ?*Area;
        pub extern fn uiNewScrollingArea(ah: *Area.Handler, width: c_int, height: c_int) ?*Area;

        pub const Type = union(enum) {
            Area,
            Scrolling: struct {
                width: c_int,
                height: c_int,
            },
        };
        pub fn New(handler: *Handler, t: Type) !*Area {
            return switch (t) {
                .Area => uiNewArea(handler),
                .Scrolling => |params| uiNewScrollingArea(handler, params.width, params.height),
            } orelse error.InitArea;
        }
    };
};

pub const Draw = opaque {
    pub const Context = opaque {
        pub extern fn uiDrawStroke(c: *Draw.Context, path: *Draw.Path, b: *Draw.Brush, p: *Draw.StrokeParams) void;
        pub extern fn uiDrawFill(c: *Draw.Context, path: *Draw.Path, b: *Draw.Brush) void;
        pub extern fn uiDrawText(c: *Draw.Context, tl: *Draw.TextLayout, x: f64, y: f64) void;

        pub const Stroke = uiDrawStroke;
        pub const Fill = uiDrawFill;
        pub const Text = uiDrawText;
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

        pub extern fn uiDrawNewPath(fillMode: Draw.Path.FillMode) ?*Draw.Path;
        pub extern fn uiDrawFreePath(p: *Draw.Path) void;
        pub extern fn uiDrawPathNewFigure(p: *Draw.Path, x: f64, y: f64) void;
        pub extern fn uiDrawPathNewFigureWithArc(p: *Draw.Path, xCenter: f64, yCenter: f64, radius: f64, startAngle: f64, sweep: f64, negative: c_int) void;
        pub extern fn uiDrawPathLineTo(p: *Draw.Path, x: f64, y: f64) void;
        pub extern fn uiDrawPathArcTo(p: *Draw.Path, xCenter: f64, yCenter: f64, radius: f64, startAngle: f64, sweep: f64, negative: c_int) void;
        pub extern fn uiDrawPathBezierTo(p: *Draw.Path, c1x: f64, c1y: f64, c2x: f64, c2y: f64, endX: f64, endY: f64) void;
        pub extern fn uiDrawPathCloseFigure(p: *Draw.Path) void;
        pub extern fn uiDrawPathAddRectangle(p: *Draw.Path, x: f64, y: f64, width: f64, height: f64) void;
        pub extern fn uiDrawPathEnded(p: *Draw.Path) c_int;
        pub extern fn uiDrawPathEnd(p: *Draw.Path) void;

        pub const New = uiDrawNewPath;
        pub const Free = uiDrawFreePath;
        pub const NewFigure = uiDrawPathNewFigure;
        pub const NewFigureWithArc = uiDrawPathNewFigureWithArc;
        pub const LineTo = uiDrawPathLineTo;
        pub const ArcTo = uiDrawPathArcTo;
        pub const BezierTo = uiDrawPathBezierTo;
        pub const CloseFigure = uiDrawPathCloseFigure;
        pub const AddRectangle = uiDrawPathAddRectangle;
        pub const Ended = uiDrawPathEnded;
        pub const End = uiDrawPathEnd;
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
        Stops: ?[*]GradientStop,
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

        pub const InitOptions = struct {
            Type: Type = .Solid,
            R: f64 = 1,
            G: f64 = 1,
            B: f64 = 1,
            A: f64 = 1,
            X0: f64 = 0,
            Y0: f64 = 0,
            X1: f64 = 1,
            Y1: f64 = 1,
            OuterRadius: f64 = 1,
            Stops: ?[]GradientStop = null,
        };

        pub fn init(options: Draw.Brush.InitOptions) @This() {
            return @This(){
                .Type = options.Type,
                .R = options.R,
                .G = options.G,
                .B = options.B,
                .A = options.A,
                .X0 = options.X0,
                .Y0 = options.Y0,
                .X1 = options.X1,
                .Y1 = options.Y1,
                .OuterRadius = options.OuterRadius,
                .Stops = if (options.Stops) |s| s.ptr else null,
                .NumStops = if (options.Stops) |s| s.len else 0,
            };
        }
    };

    pub const DefaultMiterLimit = @as(f64, 10.0);
    pub const StrokeParams = extern struct {
        Cap: LineCap,
        Join: LineJoin,
        Thickness: f64,
        MiterLimit: f64 = DefaultMiterLimit,
        Dashes: ?[*]f64,
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

        pub const InitOptions = struct {
            Cap: LineCap = .Flat,
            Join: LineJoin = .Miter,
            Thickness: f64 = 1,
            MiterLimit: f64 = DefaultMiterLimit,
            Dashes: ?[]f64 = null,
            DashPhase: f64 = 0,
        };

        pub fn init(options: Draw.StrokeParams.InitOptions) @This() {
            return @This(){
                .Cap = options.Cap,
                .Join = options.Join,
                .Thickness = options.Thickness,
                .MiterLimit = options.MiterLimit,
                .Dashes = if (options.Dashes) |s| s.ptr else null,
                .NumDashes = if (options.Dashes) |s| s.len else 0,
                .DashPhase = options.DashPhase,
            };
        }
    };

    pub const Matrix = extern struct {
        M11: f64,
        M12: f64,
        M21: f64,
        M22: f64,
        M31: f64,
        M32: f64,

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

        pub extern fn uiDrawNewTextLayout(params: *Draw.TextLayout.Params) ?*Draw.TextLayout;
        pub extern fn uiDrawFreeTextLayout(tl: *Draw.TextLayout) void;
        pub extern fn uiDrawTextLayoutExtents(tl: *Draw.TextLayout, width: *f64, height: *f64) void;

        pub const Free = uiDrawFreeTextLayout;
        pub const Size = struct {
            x: f64,
            y: f64,
        };
        pub fn TextLayoutExtents(tl: *TextLayout) Size {
            var size: Size = .{ .x = 0, .y = 0 };
            uiDrawTextLayoutExtents(tl, &size.x, &size.y);
            return size;
        }

        pub fn New(params: *TextLayout.Params) !*TextLayout {
            return uiDrawNewTextLayout(params) orelse error.InitTextLayout;
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
    pub extern fn uiNewUnderlineAttribute(u: Attribute.UnderlineType) ?*Attribute;
    pub extern fn uiAttributeUnderline(a: *const Attribute) Attribute.UnderlineType;
    pub extern fn uiNewUnderlineColorAttribute(u: Attribute.UnderlineColorType, r: f64, g: f64, b: f64, a: f64) ?*Attribute;
    pub extern fn uiAttributeUnderlineColor(a: *const Attribute, u: *Attribute.UnderlineColorType, r: *f64, g: *f64, b: *f64, alpha: *f64) void;
    pub extern fn uiAttributeFeatures(a: *const Attribute) ?*const OpenTypeFeatures;

    pub const Free = uiFreeAttribute;
    pub const GetType = uiAttributeGetType;
    const TypeOptions = union(Type) {
        Family: [*:0]const u8,
        Size: f64,
        Weight: TextWeight,
        Italic: TextItalic,
        Stretch: TextStretch,
        Color: struct { r: f64, g: f64, b: f64, a: f64 },
        Background: struct { r: f64, g: f64, b: f64, a: f64 },
        Underline: UnderlineType,
        UnderlineColor: struct { t: UnderlineColorType, r: f64, g: f64, b: f64, a: f64 },
        Features,
    };
    pub fn New(t: TypeOptions) !*Attribute {
        return switch (t) {
            .Family => |family| uiNewFamilyAttribute(family),
            .Size => |size| uiNewSizeAttribute(size),
            .Weight => |weight| uiNewWeightAttribute(weight),
            .Italic => |italic| uiNewItalicAttribute(italic),
            .Stretch => |stretch| uiNewStretchAttribute(stretch),
            .Color => |color| uiNewColorAttribute(color.r, color.g, color.b, color.a),
            .Background => |background| uiNewBackgroundAttribute(background.r, background.g, background.b, background.a),
            .Underline => |underline| uiNewUnderlineAttribute(underline),
            .UnderlineColor => |underline_color| uiNewUnderlineColorAttribute(underline_color.t, underline_color.r, underline_color.g, underline_color.b, underline_color.a),
            .Features => return error.InitFeaturesAttribute, // This attribute type cannot be constructed
        } orelse error.InitAttribute;
    }
    pub const Family = uiAttributeFamily;
    pub const Size = uiAttributeSize;
    pub const Weight = uiAttributeWeight;
    pub const Italic = uiAttributeItalic;
    pub const Stretch = uiAttributeStretch;
    pub const Color = uiAttributeColor;
    pub const Underline = uiAttributeUnderline;
    pub const UnderlineColor = uiAttributeUnderlineColor;
    pub const Features = uiAttributeFeatures;
};

pub const OpenTypeFeatures = opaque {
    pub const ForEachFunc = *const fn (*const OpenTypeFeatures, u8, u8, u8, u8, u32, ?*anyopaque) callconv(.C) ui.ForEach;
    pub fn New() !*OpenTypeFeatures {
        return uiNewOpenTypeFeatures() orelse error.InitOpenTypeFeatures;
    }

    pub extern fn uiNewOpenTypeFeatures() ?*OpenTypeFeatures;
    pub extern fn uiFreeOpenTypeFeatures(otf: *OpenTypeFeatures) void;
    pub extern fn uiOpenTypeFeaturesClone(otf: *const OpenTypeFeatures) ?*OpenTypeFeatures;
    pub extern fn uiOpenTypeFeaturesAdd(otf: *OpenTypeFeatures, a: u8, b: u8, c: u8, d: u8, value: u32) void;
    pub extern fn uiOpenTypeFeaturesRemove(otf: *OpenTypeFeatures, a: u8, b: u8, c: u8, d: u8) void;
    pub extern fn uiOpenTypeFeaturesGet(otf: *const OpenTypeFeatures, a: u8, b: u8, c: u8, d: u8, value: *u32) c_int;
    pub extern fn uiOpenTypeFeaturesForEach(otf: *const OpenTypeFeatures, f: OpenTypeFeatures.ForEachFunc, data: ?*anyopaque) void;
    pub extern fn uiNewFeaturesAttribute(otf: *const OpenTypeFeatures) ?*Attribute;

    pub const Free = uiFreeOpenTypeFeatures;
    pub const Clone = uiOpenTypeFeaturesClone;
    pub const Add = uiOpenTypeFeaturesAdd;
    pub const Remove = uiOpenTypeFeaturesRemove;
    pub const Get = uiOpenTypeFeaturesGet;
    pub const ForEach = uiOpenTypeFeaturesForEach;
    pub fn NewAttribute(otf: *const OpenTypeFeatures) !*Attribute {
        return uiNewFeaturesAttribute(otf) orelse error.InitAttribute;
    }
};

/// AttributedString is a control that allows for complex text rendering.
pub const AttributedString = opaque {
    pub const ForEachAttributeFunc = *const fn (*const AttributedString, *const Attribute, usize, usize, ?*anyopaque) callconv(.C) ui.ForEach;
    pub fn New(initialString: [*:0]const u8) !*AttributedString {
        return uiNewAttributedString(initialString) orelse error.InitAttributedString;
    }

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

    pub const Free = uiFreeAttributedString;
    pub const String = uiAttributedStringString;
    pub const AppendUnattributed = uiAttributedStringAppendUnattributed;
    pub const InsertAtUnattributed = uiAttributedStringInsertAtUnattributed;
    pub const Delete = uiAttributedStringDelete;
    pub const SetAttribute = uiAttributedStringSetAttribute;
    pub const ForEachAttribute = uiAttributedStringForEachAttribute;
    pub const NumGraphemes = uiAttributedStringNumGraphemes;
    pub const ByteIndexToGrapheme = uiAttributedStringByteIndexToGrapheme;
    pub const GraphemeToByteIndex = uiAttributedStringGraphemeToByteIndex;
};

pub const FontDescriptor = extern struct {
    Family: [*:0]const u8,
    Size: f64,
    Weight: Attribute.TextWeight,
    Italic: Attribute.TextItalic,
    Stretch: Attribute.TextStretch,

    pub extern fn uiLoadControlFont(f: *FontDescriptor) void;
    pub extern fn uiFreeFontDescriptor(desc: *FontDescriptor) void;

    pub const LoadControlFont = uiLoadControlFont;
    pub const Free = uiFreeFontDescriptor;
};

/// FontButton is a control that displays a font select dialog when it is clicked.
pub const FontButton = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }

    pub extern fn uiFontButtonFont(b: *FontButton, desc: *FontDescriptor) void;
    pub extern fn uiFontButtonOnChanged(b: *FontButton, comptime f: ?*const fn (?*FontButton, ?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;
    pub extern fn uiNewFontButton() ?*FontButton;
    pub extern fn uiFreeFontButtonFont(desc: *FontDescriptor) void;

    pub const Font = uiFontButtonFont;
    pub fn OnChanged(self: *Self, comptime T: type, comptime E: type, comptime f: *const fn (*Self, ?*T) E!void, userdata: ?*T) void {
        const callback = struct {
            fn callback(self_opt: ?*Self, t_opt: ?*anyopaque) callconv(.C) void {
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

pub const ColorValue = struct {
    red: f64,
    green: f64,
    blue: f64,
    alpha: f64,
};

/// Allows the user to select a color.
pub const ColorButton = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }

    pub extern fn uiColorButtonColor(b: *ColorButton, r: *f64, g: *f64, bl: *f64, a: *f64) void;
    pub extern fn uiColorButtonSetColor(b: *ColorButton, r: f64, g: f64, bl: f64, a: f64) void;
    pub extern fn uiColorButtonOnChanged(b: *ColorButton, f: ?*const fn (?*ColorButton, ?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;
    pub extern fn uiNewColorButton() ?*ColorButton;

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
            fn callback(self_opt: ?*Self, t_opt: ?*anyopaque) callconv(.C) void {
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
        return uiFormPadded(f) == 1;
    }
    pub fn SetPadded(f: *Form, padded: bool) void {
        uiFormSetPadded(f, @intFromBool(padded));
    }
    pub fn New() !*Form {
        return uiNewForm() orelse return error.InitForm;
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
    pub const Align = enum(c_int) {
        Fill = 0,
        Start = 1,
        Center = 2,
        End = 3,
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

    pub extern fn uiGridAppend(g: *Grid, c: ?*Control, left: c_int, top: c_int, xspan: c_int, yspan: c_int, hexpand: c_int, halign: Grid.Align, vexpand: c_int, valign: Grid.Align) void;
    pub extern fn uiGridInsertAt(g: *Grid, c: ?*Control, existing: *Control, at: Grid.At, xspan: c_int, yspan: c_int, hexpand: c_int, halign: Grid.Align, vexpand: c_int, valign: Grid.Align) void;
    pub extern fn uiGridPadded(g: *Grid) c_int;
    pub extern fn uiGridSetPadded(g: *Grid, padded: c_int) void;
    pub extern fn uiNewGrid() ?*Grid;

    pub const Append = uiGridAppend;
    pub const InsertAt = uiGridInsertAt;
    pub fn Padded(g: *Grid) bool {
        return uiGridPadded(g) == 1;
    }
    pub fn SetPadded(g: *Grid, padded: bool) void {
        uiGridSetPadded(g, @intFromBool(padded));
    }
    pub fn New() !*Grid {
        const new_grid = uiNewGrid();
        if (new_grid == null) return error.InitGrid;
        return new_grid.?;
    }
};

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
            NumColumns: *const fn (*Handler, *Model) callconv(.C) c_int,
            ColumnType: *const fn (*Handler, *Model, c_int) callconv(.C) Value.Type,
            NumRows: *const fn (*Handler, *Model) callconv(.C) c_int,
            CellValue: *const fn (*Handler, *Model, c_int, c_int) callconv(.C) ?*Value,
            SetCellValue: *const fn (*Handler, *Model, c_int, c_int, ?*const Value) callconv(.C) void,
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
        return uiTableHeaderVisible(t) == 1;
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
    pub extern fn uiTableOnRowClicked(t: *Table, f: ?*const fn (?*Table, c_int, ?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;
    pub extern fn uiTableOnRowDoubleClicked(t: *Table, f: ?*const fn (?*Table, c_int, ?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;
    pub extern fn uiTableHeaderSetSortIndicator(t: *Table, column: c_int, indicator: Table.Value.SortIndicator) void;
    pub extern fn uiTableHeaderSortIndicator(t: *Table, column: c_int) Table.Value.SortIndicator;
    pub extern fn uiTableHeaderOnClicked(t: *Table, f: ?*const fn (?*Table, c_int, ?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;
    pub extern fn uiTableColumnWidth(t: *Table, column: c_int) c_int;
    pub extern fn uiTableColumnSetWidth(t: *Table, column: c_int, width: c_int) void;

    pub fn OnRowClicked(self: *Self, comptime T: type, comptime E: type, comptime f: *const fn (*Self, ?*T) E!void, userdata: ?*T) void {
        const callback = struct {
            fn callback(self_opt: ?*Self, t_opt: ?*anyopaque) callconv(.C) void {
                const err_ctx = ErrorContext{ .TableOnRowClicked = self_opt };
                const s = self_opt orelse return error_handler(err_ctx, t_opt, error.LibUIPassedNullPointer);
                f(s, @as(?*T, @ptrCast(@alignCast(t_opt)))) catch |err| error_handler(err_ctx, t_opt, err);
            }
        }.callback;
        uiTableOnRowClicked(self, callback, userdata);
    }
    pub fn OnRowDoubleClicked(self: *Self, comptime T: type, comptime E: type, f: *const fn (*Self, ?*T) E!void, userdata: ?*T) void {
        const callback = struct {
            fn callback(self_opt: ?*Self, t_opt: ?*anyopaque) callconv(.C) void {
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
    pub extern fn uiTableOnSelectionChanged(t: *Table, f: ?*const fn (?*Table, ?*anyopaque) callconv(.C) void, data: ?*anyopaque) void;

    pub extern fn uiTableGetSelection(t: *Table) ?*Table.Selection;
    pub extern fn uiTableSetSelection(t: *Table, sel: *Table.Selection) void;
    pub extern fn uiFreeTableSelection(s: *Table.Selection) void;

    pub const GetSelectionMode = uiTableGetSelectionMode;
    pub const SetSelectionMode = uiTableSetSelectionMode;
    pub fn OnSelectionChanged(self: *Self, comptime T: type, comptime E: type, comptime f: *const fn (*Self, ?*T) E!void, userdata: ?*T) void {
        const callback = struct {
            fn callback(self_opt: ?*Self, t_opt: ?*anyopaque) callconv(.C) void {
                const err_ctx = ErrorContext{ .TableOnSelectionChanged = self_opt };
                const s = self_opt orelse return error_handler(err_ctx, t_opt, error.LibUIPassedNullPointer);
                f(s, @as(?*T, @ptrCast(@alignCast(t_opt)))) catch |err| error_handler(err_ctx, t_opt, err);
            }
        }.callback;
        uiTableOnSelectionChanged(self, callback, userdata);
    }

    pub const Selection = extern struct {
        NumRows: c_int,
        Rows: *c_int,
    };

    pub const GetSelection = uiTableGetSelection;
    pub const SetSelection = uiTableSetSelection;
};

pub const Pi = @as(f64, 3.14159265358979323846264338327950288419716939937510582097494459);
const std = @import("std");
const root = @import("root");
