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
    pub extern fn uiEditableComboboxOnChanged(c: *EditableCombobox, f: ?*const fn (?*EditableCombobox, ?*anyopaque) callconv(.c) void, data: ?*anyopaque) void;
    pub extern fn uiNewEditableCombobox() ?*EditableCombobox;

    pub const Append = uiEditableComboboxAppend;
    pub const Text = uiEditableComboboxText;
    pub const SetText = uiEditableComboboxSetText;
    pub fn OnChanged(self: *Self, comptime T: type, comptime E: type, comptime f: *const fn (*Self, ?*T) E!void, userdata: ?*T) void {
        const callback = struct {
            fn callback(self_opt: ?*Self, t_opt: ?*anyopaque) callconv(.c) void {
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

/// `Entry` is a single line text entry control. See MultilineEntry for a more advanced
/// text entry control.
pub const Entry = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }

    pub extern fn uiEntryText(e: *Entry) [*:0]u8;
    pub extern fn uiEntrySetText(e: *Entry, text: [*:0]const u8) void;
    pub extern fn uiEntryOnChanged(e: *Entry, f: ?*const fn (*Entry, ?*anyopaque) callconv(.c) void, data: ?*anyopaque) void;
    pub extern fn uiEntryReadOnly(e: *Entry) c_int;
    pub extern fn uiEntrySetReadOnly(e: *Entry, readonly: c_int) void;
    pub extern fn uiNewEntry() ?*Entry;
    pub extern fn uiNewPasswordEntry() ?*Entry;
    pub extern fn uiNewSearchEntry() ?*Entry;

    pub const Text = uiEntryText;
    pub const SetText = uiEntrySetText;
    pub fn OnChanged(self: *Self, comptime T: type, comptime E: type, comptime f: *const fn (*Self, ?*T) E!void, userdata: ?*T) void {
        const callback = struct {
            fn callback(self_opt: ?*Self, t_opt: ?*anyopaque) callconv(.c) void {
                const err_ctx = ErrorContext{ .EntryOnChanged = self_opt };
                const s = self_opt orelse return error_handler(err_ctx, t_opt, error.LibUIPassedNullPointer);
                f(s, @as(?*T, @ptrCast(@alignCast(t_opt)))) catch |err| error_handler(err_ctx, t_opt, err);
            }
        }.callback;
        uiEntryOnChanged(self, callback, userdata);
    }

    pub fn ReadOnly(e: *Entry) bool {
        return uiEntryReadOnly(e) != 0;
    }
    pub fn SetReadOnly(e: *Entry, readonly: c_int) void {
        return uiEntrySetReadOnly(e, @intFromBool(readonly));
    }
    pub const TypeEnum = enum {
        Entry,
        Password,
        Search,
    };
    pub fn New(t: TypeEnum) !*Entry {
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

/// MultilineEntry is a control that allows entering multiple lines of text.
pub const MultilineEntry = opaque {
    const Self = @This();
    pub fn as_control(self: *Self) *Control {
        return @ptrCast(@alignCast(self));
    }

    pub extern fn uiMultilineEntryText(e: *MultilineEntry) [*:0]const u8;
    pub extern fn uiMultilineEntrySetText(e: *MultilineEntry, text: [*:0]const u8) void;
    pub extern fn uiMultilineEntryAppend(e: *MultilineEntry, text: [*:0]const u8) void;
    pub extern fn uiMultilineEntryOnChanged(e: *MultilineEntry, f: ?*const fn (?*MultilineEntry, ?*anyopaque) callconv(.c) void, data: ?*anyopaque) void;
    pub extern fn uiMultilineEntryReadOnly(e: *MultilineEntry) c_int;
    pub extern fn uiMultilineEntrySetReadOnly(e: *MultilineEntry, readonly: c_int) void;
    pub extern fn uiNewMultilineEntry() ?*MultilineEntry;
    pub extern fn uiNewNonWrappingMultilineEntry() ?*MultilineEntry;

    pub const Text = uiMultilineEntryText;
    pub const SetText = uiMultilineEntrySetText;
    pub const Append = uiMultilineEntryAppend;
    pub fn OnChanged(self: *Self, comptime T: type, comptime E: type, comptime f: *const fn (*Self, ?*T) E!void, userdata: ?*T) void {
        const callback = struct {
            fn callback(self_opt: ?*Self, t_opt: ?*anyopaque) callconv(.c) void {
                const err_ctx = ErrorContext{ .MultilineEntryOnChanged = self_opt };
                const s = self_opt orelse return error_handler(err_ctx, t_opt, error.LibUIPassedNullPointer);
                f(s, @as(?*T, @ptrCast(@alignCast(t_opt)))) catch |err| error_handler(err_ctx, t_opt, err);
            }
        }.callback;
        uiMultilineEntryOnChanged(self, callback, userdata);
    }
    pub fn ReadOnly(e: *MultilineEntry) bool {
        return uiMultilineEntryReadOnly(e) != 0;
    }
    pub fn SetReadOnly(e: *MultilineEntry, readonly: bool) void {
        return uiMultilineEntrySetReadOnly(e, @intFromBool(readonly));
    }
    pub const TypeEnum = enum {
        Wrapping,
        NonWrapping,
    };
    pub fn New(t: TypeEnum) !*MultilineEntry {
        return switch (t) {
            .Wrapping => uiNewMultilineEntry(),
            .NonWrapping => uiNewNonWrappingMultilineEntry(),
        } orelse error.InitMultilineEntry;
    }
};

const Control = ui.Control;
const error_handler = ui.error_handler;
const ErrorContext = ui.ErrorContext;

const ui = @import("ui.zig");
