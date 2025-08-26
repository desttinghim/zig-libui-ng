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
    @branchHint(.cold);
    var buffer: [4096]u8 = undefined;
    const message = std.fmt.bufPrint(&buffer, "Error while executing callback - [Context] {} [User Data] {*} [Error] {}", .{ context, userdata, err }) catch buffer[0..];
    @panic(message);
}

/// Queue a function to be called in a loop by `ui.Main`.
pub fn QueueMain(comptime T: type, comptime E: type, comptime callback: *const fn (?*T) E!void, data: ?*T) void {
    const cb = struct {
        fn cb(t_opt: ?*anyopaque) callconv(.c) void {
            @call(.auto, callback, .{@as(?*T, @ptrCast(@alignCast(t_opt)))}) catch |err| error_handler(.QueueMain, t_opt, err);
        }
    }.cb;
    uiQueueMain(cb, data);
}

/// Queue a function to be called after `milliseconds`. Do not rely on this if you need precise
/// time tracking.
pub fn Timer(comptime T: type, comptime E: type, milliseconds: c_int, comptime callback: *const fn (?*T) E!TimerAction, data: ?*T) void {
    const cb = struct {
        fn cb(t_opt: ?*anyopaque) callconv(.c) TimerAction {
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
        fn cb(t_opt: ?*anyopaque) callconv(.c) QuitAction {
            return @call(.auto, callback, .{@as(?*T, @ptrCast(@alignCast(t_opt)))}) catch |err| {
                error_handler(.OnShouldQuit, t_opt, err);
                return .should_quit;
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
pub extern fn uiQueueMain(f: ?*const fn (?*anyopaque) callconv(.c) void, data: ?*anyopaque) void;
pub extern fn uiTimer(milliseconds: c_int, f: ?*const fn (?*anyopaque) callconv(.c) TimerAction, data: ?*anyopaque) void;
pub extern fn uiOnShouldQuit(f: ?*const fn (?*anyopaque) callconv(.c) QuitAction, data: ?*anyopaque) void;
pub extern fn uiFreeText(text: [*:0]const u8) void;

pub const Control = @import("control.zig").Control;
pub const Window = @import("window.zig").Window;

pub const layout = @import("layout.zig");
pub const Form = layout.Form;
pub const Box = layout.Box;
pub const Grid = layout.Grid;
pub const Group = layout.Group;
pub const Seperator = layout.Seperator;
pub const Tab = layout.Tab;

pub const button = @import("button.zig");
pub const Button = button.Button;
pub const ColorButton = button.ColorButton;
pub const FontButton = button.FontButton;

pub const input = @import("input.zig");
pub const DateTimePicker = input.DateTimePicker;
pub const Checkbox = input.Checkbox;
pub const Combobox = input.Combobox;
pub const RadioButtons = input.RadioButtons;
pub const Slider = input.Slider;
pub const Spinbox = input.Spinbox;

pub const text = @import("text.zig");
pub const EditableCombobox = text.EditableCombobox;
pub const Entry = text.Entry;
pub const Label = text.Label;
pub const MultilineEntry = text.MultilineEntry;

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

pub const menu = @import("menu.zig");
pub const Menu = menu.Menu;
pub const MenuItem = menu.MenuItem;

pub const draw = @import("draw.zig");
pub const Area = draw.Area;
pub const Attribute = draw.Attribute;
pub const AttributedString = draw.AttributedString;
pub const Draw = draw.Draw;
pub const FontDescriptor = draw.FontDescriptor;
pub const OpenTypeFeatures = draw.OpenTypeFeatures;

pub const table = @import("table.zig");
pub const Image = table.Image;
pub const Table = table.Table;

const std = @import("std");
const root = @import("root");
