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
        ExtKey: ExtKeyEnum,
        Modifier: Modifiers,
        Modifiers: Modifiers,
        Up: c_int,

        pub const ExtKeyEnum = enum(c_int) {
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
            _,
        };
    };

    pub const Handler = extern struct {
        Draw: *const fn (*Handler, *Area, *Draw.Params) callconv(.c) void,
        MouseEvent: *const fn (*Handler, *Area, *MouseEvent) callconv(.c) void,
        MouseCrossed: *const fn (*Handler, *Area, c_int) callconv(.c) void,
        DragBroken: *const fn (*Handler, *Area) callconv(.c) void,
        KeyEvent: *const fn (*Handler, *Area, *KeyEvent) callconv(.c) c_int,

        pub extern fn uiNewArea(ah: *Area.Handler) ?*Area;
        pub extern fn uiNewScrollingArea(ah: *Area.Handler, width: c_int, height: c_int) ?*Area;

        pub const TypeEnum = union(enum) {
            Area,
            Scrolling: struct {
                width: c_int,
                height: c_int,
            },
        };
        pub fn New(handler: *Handler, t: TypeEnum) !*Area {
            return switch (t) {
                .Area => uiNewArea(handler),
                .Scrolling => |params| uiNewScrollingArea(handler, params.width, params.height),
            } orelse error.InitArea;
        }
    };
};

pub const Attribute = opaque {
    pub const TypeEnum = enum(c_int) {
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
    const TypeOptions = union(TypeEnum) {
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

/// AttributedString is a control that allows for complex text rendering.
pub const AttributedString = opaque {
    pub const ForEachAttributeFunc = *const fn (*const AttributedString, *const Attribute, usize, usize, ?*anyopaque) callconv(.c) ui.ForEach;
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

pub const Draw = opaque {
    pub const Context = opaque {
        pub extern fn uiDrawStroke(c: *Draw.Context, path: *Draw.Path, b: *Draw.Brush, p: *Draw.StrokeParams) void;
        pub extern fn uiDrawFill(c: *Draw.Context, path: *Draw.Path, b: *Draw.Brush) void;
        pub extern fn uiDrawText(c: *Draw.Context, tl: *Draw.TextLayout, x: f64, y: f64) void;
        pub extern fn uiDrawTransform(c: *Draw.Context, m: *ui.Draw.Matrix) void;
        pub extern fn uiDrawClip(c: *Draw.Context, m: *ui.Draw.Matrix) void;
        pub extern fn uiDrawSave(c: *Draw.Context) void;
        pub extern fn uiDrawRestore(c: *Draw.Context) void;

        pub const Stroke = uiDrawStroke;
        pub const Fill = uiDrawFill;
        pub const Text = uiDrawText;
        pub const Transform = uiDrawTransform;
        pub const Clip = uiDrawClip;
        pub const Save = uiDrawSave;
        pub const Restore = uiDrawRestore;
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
        pub fn NewFigureWithArc(p: *Draw.Path, xCenter: f64, yCenter: f64, radius: f64, startAngle: f64, sweep: f64, negative: bool) void {
            uiDrawPathNewFigureWithArc(p, xCenter, yCenter, radius, startAngle, sweep, @intFromBool(negative));
        }
        pub const LineTo = uiDrawPathLineTo;
        pub fn ArcTo(p: *Draw.Path, xCenter: f64, yCenter: f64, radius: f64, startAngle: f64, sweep: f64, negative: bool) void {
            uiDrawPathArcTo(p, xCenter, yCenter, radius, startAngle, sweep, @intFromBool(negative));
        }
        pub const BezierTo = uiDrawPathBezierTo;
        pub const CloseFigure = uiDrawPathCloseFigure;
        pub const AddRectangle = uiDrawPathAddRectangle;
        pub fn Ended(p: *Draw.Path) bool {
            return uiDrawPathEnded(p) != 0;
        }
        pub const End = uiDrawPathEnd;
    };

    pub const Brush = extern struct {
        Type: TypeEnum,
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

        pub const TypeEnum = enum(c_int) {
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
            Type: TypeEnum = .Solid,
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
        M11: f64 = 0,
        M12: f64 = 0,
        M21: f64 = 0,
        M22: f64 = 0,
        M31: f64 = 0,
        M32: f64 = 0,

        pub extern fn uiDrawMatrixSetIdentity(m: *Draw.Matrix) void;
        pub extern fn uiDrawMatrixTranslate(m: *Draw.Matrix, x: f64, y: f64) void;
        pub extern fn uiDrawMatrixScale(m: *Draw.Matrix, xCenter: f64, yCenter: f64, x: f64, y: f64) void;
        pub extern fn uiDrawMatrixRotate(m: *Draw.Matrix, x: f64, y: f64, amount: f64) void;
        pub extern fn uiDrawMatrixSkew(m: *Draw.Matrix, x: f64, y: f64, xamount: f64, yamount: f64) void;
        pub extern fn uiDrawMatrixMultiply(dest: *Draw.Matrix, src: *Draw.Matrix) void;
        pub extern fn uiDrawMatrixInvertible(m: *Draw.Matrix) c_int;
        pub extern fn uiDrawMatrixInvert(m: *Draw.Matrix) c_int;
        pub extern fn uiDrawMatrixTransformPoint(m: *Draw.Matrix, x: *f64, y: *f64) void;
        pub extern fn uiDrawMatrixTransformSize(m: *Draw.Matrix, x: *f64, y: *f64) void;

        pub const SetIdentity = uiDrawMatrixSetIdentity;
        pub const Translate = uiDrawMatrixTranslate;
        pub const Scale = uiDrawMatrixScale;
        pub const Rotate = uiDrawMatrixRotate;
        pub const Skew = uiDrawMatrixSkew;
        pub const Multiply = uiDrawMatrixMultiply;
        pub const Invertible = uiDrawMatrixInvertible;
        pub const Invert = uiDrawMatrixInvert;
        pub const TransformPoint = uiDrawMatrixTransformPoint;
        pub const TransformSize = uiDrawMatrixTransformSize;

        pub fn init() @This() {
            var this = @This(){};
            this.SetIdentity();
            return this;
        }
    };

    pub const TextLayout = opaque {
        pub const Params = extern struct {
            String: ?*AttributedString,
            DefaultFont: *FontDescriptor,
            Width: f64,
            Align: AlignEnum,

            pub const AlignEnum = enum(c_int) {
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

pub const OpenTypeFeatures = opaque {
    pub const ForEachFunc = *const fn (*const OpenTypeFeatures, u8, u8, u8, u8, u32, ?*anyopaque) callconv(.c) ui.ForEach;
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

const Control = ui.Control;
const ErrorContext = ui.ErrorContext;
const error_handler = ui.error_handler;

pub const ui = @import("ui.zig");
