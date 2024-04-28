const std = @import("std");
const ui = @import("ui");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var init_data = ui.InitData{
        .options = .{ .Size = 0 },
    };
    ui.Init(&init_data) catch {
        std.debug.print("Error initializing LibUI: {s}\n", .{init_data.get_error()});
        init_data.free_error();
        return;
    };
    defer ui.Uninit();

    //
    const circle_drawer = try CircleDrawer.New(allocator);
    defer circle_drawer.Destroy();

    // Initialize components
    const main_window = try ui.Window.New("Hello, World!", 320, 240, .hide_menubar);
    const vbox = try ui.Box.New(.Vertical);
    const hbox = try ui.Box.New(.Horizontal);
    hbox.SetPadded(true);
    const btn_undo = try ui.Button.New("Undo");
    const btn_redo = try ui.Button.New("Redo");
    const circle_drawer_area = try circle_drawer.NewArea();

    // Build layout heirarchy
    main_window.SetChild(vbox.as_control());
    vbox.Append(hbox.as_control(), .dont_stretch);
    vbox.Append(circle_drawer_area.as_control(), .stretch);

    hbox.Append(btn_undo.as_control(), .stretch);
    hbox.Append(btn_redo.as_control(), .stretch);

    // Connect callbacks
    main_window.OnClosing(void, ui.Error, on_closing, null);
    btn_undo.OnClicked(CircleDrawer, CircleDrawer.Error, on_undo_clicked, circle_drawer);
    btn_redo.OnClicked(CircleDrawer, CircleDrawer.Error, on_redo_clicked, circle_drawer);

    // Show window and start libui's main loop
    main_window.as_control().Show();

    ui.Main();
}

pub fn on_closing(_: *ui.Window, _: ?*void) !ui.Window.ClosingAction {
    ui.Quit();
    return .should_close;
}

pub fn on_undo_clicked(_: *ui.Button, circle_drawer_opt: ?*CircleDrawer) CircleDrawer.Error!void {
    const circle_drawer = circle_drawer_opt orelse return error.LibUINullUserdata;

    circle_drawer.undo();
    try circle_drawer.updateCircleList();
    circle_drawer.area.?.QueueRedrawAll();
}

pub fn on_redo_clicked(_: *ui.Button, circle_drawer_opt: ?*CircleDrawer) CircleDrawer.Error!void {
    const circle_drawer = circle_drawer_opt orelse return error.LibUINullUserdata;

    circle_drawer.redo();
    try circle_drawer.updateCircleList();
    circle_drawer.area.?.QueueRedrawAll();
}

const CircleDrawer = struct {
    alloc: std.mem.Allocator,
    handler: ui.Area.Handler,
    area: ?*ui.Area = null,
    actions: std.ArrayList(Action),
    action_current: usize = 0,
    circles: std.AutoArrayHashMap(usize, Circle),
    radius_current: f64 = 10,

    const Error = ui.Error || error{ OutOfMemory, MissingCircle };

    const Action = union(enum) {
        add_circle: struct { id: usize, x: f64, y: f64, radius: f64 },
        fill_circle: struct { which: usize },
        adjust_diameter: struct { which: usize, new_radius: f64 },
    };

    const Circle = struct {
        x: f64,
        y: f64,
        radius: f64,
        is_filled: bool,
    };

    pub fn New(alloc: std.mem.Allocator) !*@This() {
        const this = try alloc.create(@This());
        errdefer alloc.destroy(this);
        this.* = .{
            .alloc = alloc,
            .actions = std.ArrayList(Action).init(alloc),
            .circles = std.AutoArrayHashMap(usize, Circle).init(alloc),
            .handler = ui.Area.Handler{
                .Draw = @This().Draw,
                .MouseEvent = @This().MouseEvent,
                .MouseCrossed = @This().MouseCrossed,
                .DragBroken = @This().DragBroken,
                .KeyEvent = @This().KeyEvent,
            },
        };
        return this;
    }

    fn undo(circle_drawer: *CircleDrawer) void {
        circle_drawer.action_current -|= 1;
    }

    fn redo(circle_drawer: *CircleDrawer) void {
        if (circle_drawer.action_current < circle_drawer.actions.items.len) {
            circle_drawer.action_current += 1;
        }
    }

    fn beginAddAction(circle_drawer: *CircleDrawer) void {
        if (circle_drawer.action_current < circle_drawer.actions.items.len) {
            circle_drawer.actions.shrinkRetainingCapacity(circle_drawer.action_current);
        }
    }

    fn fillCircle(circle_drawer: *CircleDrawer, id: usize) !void {
        if (circle_drawer.circles.get(id)) |circle| {
            if (circle.is_filled) return; // don't duplicate fill actions
        }
        circle_drawer.beginAddAction();
        try circle_drawer.actions.append(.{ .fill_circle = .{
            .which = id,
        } });
        circle_drawer.action_current += 1;
    }

    fn addCircle(circle_drawer: *CircleDrawer, x: f64, y: f64, radius: f64) !void {
        circle_drawer.beginAddAction();
        const new_id = circle_drawer.action_current;
        try circle_drawer.actions.append(.{ .add_circle = .{
            .id = new_id,
            .x = x,
            .y = y,
            .radius = radius,
        } });
        circle_drawer.action_current += 1;
    }

    fn updateCircleList(circle_drawer: *CircleDrawer) !void {
        circle_drawer.circles.clearRetainingCapacity();
        for (circle_drawer.actions.items[0..circle_drawer.action_current]) |action| {
            switch (action) {
                .add_circle => |circle| {
                    try circle_drawer.circles.put(circle.id, .{
                        .x = circle.x,
                        .y = circle.y,
                        .radius = circle.radius,
                        .is_filled = false,
                    });
                },
                .fill_circle => |fill| {
                    const circle = circle_drawer.circles.getPtr(fill.which) orelse return error.MissingCircle;
                    circle.*.is_filled = true;
                },
                .adjust_diameter => |adjust| {
                    const circle = circle_drawer.circles.getPtr(adjust.which) orelse return error.MissingCircle;
                    circle.*.radius = adjust.new_radius;
                },
            }
        }
    }

    pub fn Destroy(this: *@This()) void {
        this.actions.deinit();
        this.circles.deinit();
        this.alloc.destroy(this);
    }

    pub fn NewArea(this: *@This()) !*ui.Area {
        const new_area = try this.handler.New(.Area);
        this.area = new_area;
        return new_area;
    }

    fn Draw(handler: *ui.Area.Handler, area: *ui.Area, draw_params: *ui.Draw.Params) callconv(.C) void {
        const this: *@This() = @fieldParentPtr("handler", handler);
        _ = area;

        const context = draw_params.Context orelse return;
        var brush = ui.Draw.Brush.init(.{});
        var stroke_params = ui.Draw.StrokeParams.init(.{});

        // Draw the outline of a semi-circle
        var iter = this.circles.iterator();
        while (iter.next()) |kv| {
            const circle = kv.value_ptr;
            var path = ui.Draw.Path.New(.Winding) orelse return;
            defer path.Free();

            path.NewFigureWithArc(circle.x, circle.y, circle.radius, 0, 2 * std.math.pi, 0);
            path.End();

            if (circle.is_filled) {
                context.Fill(path, &brush);
            } else {
                context.Stroke(path, &brush, &stroke_params);
            }
        }
    }

    fn MouseEvent(handler: *ui.Area.Handler, area: *ui.Area, mouse_event: *ui.Area.MouseEvent) callconv(.C) void {
        const this: *@This() = @fieldParentPtr("handler", handler);

        if (mouse_event.Down & 0b1 == 0) {
            // If mouse button one is NOT down
            return;
        }

        var nearest_circle: ?usize = null;
        var nearest_dist: ?f64 = null;

        var iter = this.circles.iterator();
        while (iter.next()) |kv| {
            const circle = kv.value_ptr;
            const x = circle.x - mouse_event.X;
            const y = circle.y - mouse_event.Y;
            const dist_squared = (x * x) + (y * y);
            const radius_squared = circle.radius * circle.radius;
            if (dist_squared < radius_squared) {
                if (nearest_dist) |dist| {
                    if (dist_squared < dist) {
                        nearest_circle = kv.key_ptr.*;
                        nearest_dist = dist_squared;
                    }
                } else {
                    nearest_dist = dist_squared;
                    nearest_circle = kv.key_ptr.*;
                }
            }
        }
        if (nearest_circle) |id| {
            this.fillCircle(id) catch {};
        } else {
            this.addCircle(mouse_event.X, mouse_event.Y, this.radius_current) catch {};
        }
        this.updateCircleList() catch {};

        area.QueueRedrawAll();
    }

    fn MouseCrossed(handler: *ui.Area.Handler, area: *ui.Area, cross_value: c_int) callconv(.C) void {
        _ = area;
        _ = cross_value;
        const this: *@This() = @fieldParentPtr("handler", handler);
        _ = this;
    }

    fn DragBroken(handler: *ui.Area.Handler, area: *ui.Area) callconv(.C) void {
        _ = area;
        const this: *@This() = @fieldParentPtr("handler", handler);
        _ = this;
    }

    fn KeyEvent(handler: *ui.Area.Handler, area: *ui.Area, key_event: *ui.Area.KeyEvent) callconv(.C) c_int {
        const this: *@This() = @fieldParentPtr("handler", handler);
        if (key_event.Modifiers.Ctrl and key_event.Up == 0) {
            switch (key_event.Key) {
                'z' => {
                    std.log.info("undoing...", .{});
                    this.undo();
                    this.updateCircleList() catch {};
                    area.QueueRedrawAll();
                },
                'y' => {
                    std.log.info("redoing...", .{});
                    this.redo();
                    this.updateCircleList() catch {};
                    area.QueueRedrawAll();
                },
                else => {},
            }
        }
        return 0;
    }
};
