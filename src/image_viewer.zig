const std = @import("std");
const rl = @import("raylib");
const data_types = @import("data_types.zig");


pub fn load(path: []const u8) ?data_types.ImageState {
    // raylib expects a null-terminated string
    const c_path: [:0]const u8 = std.mem.span(
        @as([*:0]const u8, @ptrCast(path.ptr))
    );
    const img = rl.loadImage(c_path) catch {
        std.log.err("Failed to load image: {s}", .{path});
        return null;
    };
    defer rl.unloadImage(img);
    const tex = rl.loadTextureFromImage(img) catch {
        std.log.err("Failed to create texture from image: {s}", .{path});
        return null;
    };

    return data_types.ImageState{
        .texture = tex,
        .width = img.width,
        .height = img.height,
    };
}

pub fn unload(state: *data_types.ImageState) void {
    rl.unloadTexture(state.texture);
    state.* = undefined;
}

pub fn draw(state: *data_types.ImageState) void {
    // Handle zoom with mouse wheel
    const wheel = rl.getMouseWheelMove();
    if (wheel != 0) {
        state.zoom += wheel * 0.1;
        state.zoom = std.math.clamp(state.zoom, 0.1, 10.0);
    }

    // Handle pan with middle mouse button
    if (rl.isMouseButtonDown(.middle)) {
        const delta = rl.getMouseDelta();
        state.offset_x += delta.x;
        state.offset_y += delta.y;
    }

    // Fit image to window, then apply user zoom
    const win_w: f32 = @floatFromInt(rl.getScreenWidth());
    const win_h: f32 = @floatFromInt(rl.getScreenHeight());
    const img_w: f32 = @floatFromInt(state.width);
    const img_h: f32 = @floatFromInt(state.height);

    const fit_scale = @min(win_w / img_w, win_h / img_h);
    const scale = fit_scale * state.zoom;

    const draw_w = img_w * scale;
    const draw_h = img_h * scale;

    // Center the image
    const x = (win_w - draw_w) / 2.0 + state.offset_x;
    const y = (win_h - draw_h) / 2.0 + state.offset_y;

    const src = rl.Rectangle{
        .x = 0,
        .y = 0,
        .width = img_w,
        .height = img_h,
    };

    const dst = rl.Rectangle{
        .x = x,
        .y = y,
        .width = draw_w,
        .height = draw_h,
    };

    rl.drawTexturePro(
        state.texture,
        src,
        dst,
        .{ .x = 0, .y = 0 },
        0.0,
        rl.Color.white,
    );
}
