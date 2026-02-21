const std = @import("std");
const rl = @import("raylib");
const data_types = @import("data_types.zig");

var show_file_menu: bool = false;


pub fn drawDropPrompt() void {
    const win_w = rl.getScreenWidth();
    const win_h = rl.getScreenHeight();

    const text = "Drop an image or video file here";
    const font_size = 24;
    const text_w = rl.measureText(text, font_size);

    rl.drawText(
        text,
        @divTrunc(win_w - text_w, 2),
        @divTrunc(win_h, 2) - 12,
        font_size,
        rl.Color.init(180, 180, 180, 255),
    );

    // Draw a dashed border hint
    const margin = 40;
    rl.drawRectangleLines(
        margin,
        margin,
        win_w - margin * 2,
        win_h - margin * 2,
        rl.Color.init(80, 80, 80, 255),
    );
}

pub fn drawHUD(state: *const data_types.AppState) void {
    // Show filename in bottom right
    if (state.file_path) |path| {
        const basename = std.fs.path.basename(path);
        const c_name: [:0]const u8 = std.mem.span(@as([*:0]const u8, @ptrCast(basename.ptr)));
        rl.drawText(
            c_name,
            rl.getScreenWidth() - 10 - rl.measureText(c_name, 18),
            rl.getScreenHeight() - 28,
            18,
            rl.Color.init(200, 200, 200, 200));
    }

    // Show FPS in top-right
    rl.drawFPS(rl.getScreenWidth() - 90, 10);

    // Show controls hint at bottom middle
    const hint = "[Scroll] Zoom  [Middle-click] Pan  [Space] Play/Pause  [Esc] Quit";
    const hint_w = rl.measureText(hint, 18);
    rl.drawText(
        hint,
        @divTrunc(rl.getScreenWidth() - hint_w, 2),
        rl.getScreenHeight() - 30,
        18,
        rl.Color.init(120, 120, 120, 180),
    );
}

pub fn drawMenuBar() ?MenuAction {
    const bar_h = 28;
    // Menu bar background
    rl.drawRectangle(0, 0, rl.getScreenWidth(), bar_h,
        rl.Color.init(45, 45, 45, 255));

    // "File" button
    const file_rect = rl.Rectangle{ .x = 4, .y = 2, .width = 50, .height = 24 };
    if (
        rl.isMouseButtonPressed(.left) and
        rl.checkCollisionPointRec(rl.getMousePosition(), file_rect)
    ) {
        show_file_menu = !show_file_menu;
    }

    rl.drawText("File", 12, 6, 16, rl.Color.init(220, 220, 220, 255));

    if (show_file_menu) {
        // Dropdown background
        rl.drawRectangle(4, bar_h, 140, 56,
            rl.Color.init(50, 50, 50, 255));

        // "Open File" option
        const open_file_rect = rl.Rectangle{ .x = 4, .y = bar_h, .width = 140, .height = 28 };
        if (rl.checkCollisionPointRec(rl.getMousePosition(), open_file_rect)) {
            rl.drawRectangleRec(open_file_rect, rl.Color.init(70, 70, 70, 255));
            if (rl.isMouseButtonPressed(.left)) {
                std.log.debug("open_file_rect pressed\n", .{});
                show_file_menu = false;
                return .open_file;
            }
        }
        rl.drawText("Open File", 12, bar_h + 6, 14,
            rl.Color.init(200, 200, 200, 255));

        // "Open Folder" option
        const open_folder_rect = rl.Rectangle{ .x = 4, .y = bar_h + 28, .width = 140, .height = 28 };
        if (rl.checkCollisionPointRec(rl.getMousePosition(), open_folder_rect)) {
            rl.drawRectangleRec(open_folder_rect, rl.Color.init(70, 70, 70, 255));
            if (rl.isMouseButtonPressed(.left)) {
                std.log.debug("open_folder_rect pressed\n", .{});
                show_file_menu = false;
                return .open_folder;
            }
        }
        rl.drawText("Open Folder", 12, bar_h + 34, 14,
            rl.Color.init(200, 200, 200, 255));
    }

    // Close menu if clicking outside
    if (
        rl.isMouseButtonPressed(.left) and
        show_file_menu and
        !rl.checkCollisionPointRec(rl.getMousePosition(), file_rect)
    ) {
        std.log.debug("isMouseButtonPressed(.left) and show_file_menu\n", .{});
        show_file_menu = false;
    }

    return null;
}

pub const MenuAction = enum {
    open_file,
    open_folder,
};
