pub const Control = extern struct {
    Signature: u32,
    OSSignature: u32,
    TypeSignature: u32,
    _Destroy: ?*const fn (*Control) callconv(.c) void,
    _Handle: ?*const fn (*Control) callconv(.c) usize,
    _Parent: ?*const fn (*Control) callconv(.c) *Control,
    _SetParent: ?*const fn (*Control, *Control) callconv(.c) void,
    _Toplevel: ?*const fn (*Control) callconv(.c) c_int,
    _Visible: ?*const fn (*Control) callconv(.c) c_int,
    _Show: ?*const fn (*Control) callconv(.c) void,
    _Hide: ?*const fn (*Control) callconv(.c) void,
    _Enabled: ?*const fn (*Control) callconv(.c) c_int,
    _Enable: ?*const fn (*Control) callconv(.c) void,
    _Disable: ?*const fn (*Control) callconv(.c) void,

    pub extern fn uiControlDestroy(c: *Control) void;
    pub extern fn uiControlHandle(c: *Control) usize;
    pub extern fn uiControlParent(c: *Control) ?*Control;
    pub extern fn uiControlSetParent(c: *Control, parent: ?*Control) void;
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
        return uiControlToplevel(c) != 0;
    }
    pub fn Visible(c: *Control) bool {
        return uiControlVisible(c) != 0;
    }
    pub fn Enabled(c: *Control) bool {
        return uiControlEnabled(c) != 0;
    }
    pub fn Alloc(n: usize, OSsig: u32, typesig: u32, typenamestr: [*:0]const u8) ?[*]Control {
        return uiAllocControl(n, OSsig, typesig, typenamestr);
    }
    pub fn EnabledToUser(c: *Control) bool {
        return uiControlEnabledToUser(c) != 0;
    }
};
