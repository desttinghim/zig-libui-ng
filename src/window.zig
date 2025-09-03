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
    pub extern fn uiWindowOnPositionChanged(w: *Window, f: ?*const fn (*Window, ?*anyopaque) callconv(.c) void, data: ?*anyopaque) void;
    pub extern fn uiWindowContentSize(w: *Window, width: *c_int, height: *c_int) void;
    pub extern fn uiWindowSetContentSize(w: *Window, width: c_int, height: c_int) void;
    pub extern fn uiWindowFullscreen(w: *Window) c_int;
    pub extern fn uiWindowSetFullscreen(w: *Window, fullscreen: c_int) void;
    pub extern fn uiWindowOnContentSizeChanged(w: *Window, f: ?*const fn (*Window, ?*anyopaque) callconv(.c) void, data: ?*anyopaque) void;
    pub extern fn uiWindowOnClosing(w: *Window, f: ?*const fn (*Window, ?*anyopaque) callconv(.c) Window.ClosingAction, data: ?*anyopaque) void;
    pub extern fn uiWindowOnFocusChanged(w: *Window, f: ?*const fn (*Window, ?*anyopaque) callconv(.c) void, data: ?*anyopaque) void;
    pub extern fn uiWindowFocused(w: *Window) c_int;
    pub extern fn uiWindowBorderless(w: *Window) c_int;
    pub extern fn uiWindowSetBorderless(w: *Window, borderless: c_int) void;
    pub extern fn uiWindowSetChild(w: *Window, child: ?*Control) void;
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
        return uiWindowFullscreen(w) != 0;
    }

    pub fn SetFullscreen(w: *Window, fullscreen: bool) void {
        uiWindowSetFullscreen(w, @intFromBool(fullscreen));
    }

    pub fn Focused(w: *Window) bool {
        return uiWindowFocused(w) != 0;
    }

    pub fn Borderless(w: *Window) bool {
        return uiWindowBorderless(w) != 0;
    }

    pub fn SetBorderless(w: *Window, borderless: bool) void {
        uiWindowSetBorderless(w, @intFromBool(borderless));
    }

    pub fn Margined(w: *Window) bool {
        uiWindowMargined(w) != 0;
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

    /// @param window   - Pointer to ui Window
    /// @param T        - The type of the userdata parameter
    /// @param E        - The error return type of the callback function, often `ui.Error`
    /// @param f        - Callback function for event
    /// @param userdata - Pointer to value of type T, to be passed to the callback
    ///
    /// Call this function to have `f` called when the Window's position has changed.
    pub fn OnPositionChanged(window: *Window, comptime T: type, comptime E: type, comptime f: *const fn (*Window, ?*T) E!void, userdata: ?*T) void {
        const callback = struct {
            fn callback(window_opt: ?*Window, t_opt: ?*anyopaque) callconv(.c) void {
                const err_ctx = ErrorContext{ .WindowOnPositionChanged = window_opt };
                const w = window_opt orelse return error_handler(err_ctx, t_opt, error.LibUIPassedNullPointer);
                f(w, @as(?*T, @ptrCast(@alignCast(t_opt)))) catch |err| error_handler(err_ctx, t_opt, err);
            }
        }.callback;
        uiWindowOnPositionChanged(window, callback, userdata);
    }

    /// @param window   - Pointer to ui Window
    /// @param T        - The type of the userdata parameter
    /// @param E        - The error return type of the callback function, often `ui.Error`
    /// @param f        - Callback function for event
    /// @param userdata - Pointer to value of type T, to be passed to the callback
    ///
    /// Call this function to have `f` called when the Window has been resized.
    pub fn OnContentSizeChanged(window: *Window, comptime T: type, comptime E: type, comptime f: *const fn (*Window, ?*T) E!void, userdata: ?*T) void {
        const callback = struct {
            fn callback(window_opt: ?*Window, t_opt: ?*anyopaque) callconv(.c) void {
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
    /// @param window   - Pointer to ui Window
    /// @param T        - The type of the userdata parameter
    /// @param E        - The error return type of the callback function, often `ui.Error`
    /// @param f        - Callback function for event
    /// @param userdata - Pointer to value of type T, to be passed to the callback
    ///
    /// Call this function to have `f` called when the user attempts to close the window.
    /// For most single window programs, this will correspond to quiting the application
    /// and the handler should call `ui.Quit()` then return `.should_close`. If you need to
    /// run cleanup code on a window level construct (for example, a document), this is a
    /// good place to handle it.
    pub fn OnClosing(window: *Window, comptime T: type, comptime E: type, comptime f: *const fn (*Window, ?*T) E!ClosingAction, userdata: ?*T) void {
        const callback = struct {
            fn callback(window_opt: ?*Window, t_opt: ?*anyopaque) callconv(.c) ClosingAction {
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
            fn callback(window_opt: ?*Window, t_opt: ?*anyopaque) callconv(.c) void {
                const err_ctx = ErrorContext{ .WindowOnFocusChanged = window_opt };
                const w = window_opt orelse return error_handler(err_ctx, t_opt, error.LibUIPassedNullPointer);
                f(w, @as(?*T, @ptrCast(@alignCast(t_opt)))) catch |err| error_handler(err_ctx, t_opt, err);
            }
        }.callback;
        uiWindowOnFocusChanged(window, callback, userdata);
    }

    // Dialog boxes
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

pub const Control = ui.Control;
pub const ErrorContext = ui.ErrorContext;
pub const error_handler = ui.error_handler;

pub const ui = @import("ui.zig");
