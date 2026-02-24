const std = @import("std");
const rl = @import("raylib");

const image_viewer = @import("image_viewer.zig");
const video_player = @import("video_player.zig");
const ui = @import("ui.zig");
const data_types = @import("data_types.zig");
const constants = @import("constants.zig");
const dialog = @import("dialog.zig");
const file_io_utils = @import("file_io_utils.zig");

fn freeMediaFileList(files: *std.ArrayList([]const u8), allocator: std.mem.Allocator) void {
    for (files.items) |file_path| {
        allocator.free(file_path);
    }
    files.deinit(allocator);
    files.* = .empty;
}

fn setMediaState(
    state: *data_types.AppState,
    allocator: std.mem.Allocator,
    media_path: []const u8
) !void {
    std.log.debug("Setting media state for {s}", .{media_path});
    const abs_path = try file_io_utils.convertPathToAbsolute(
        media_path,
        allocator
    );
    defer allocator.free(abs_path);
    std.log.debug("Absolute path: {s}", .{abs_path});
    state.media_type = file_io_utils.classifyFile(abs_path);

    switch (state.media_type) {
        .image => state.image_state = image_viewer.load(abs_path),
        .video => state.video_state = video_player.open(abs_path),
        .unknown => std.log.warn("Unknown file type: {s}", .{abs_path}),
    }
}

fn setMediaFiles(
    allocator: std.mem.Allocator,
    media_path: []const u8,
    media_files: *std.ArrayList([]const u8)
) !void {
    freeMediaFileList(media_files, allocator);
    const abs_path: []const u8 = try file_io_utils.convertPathToAbsolute(
        media_path,
        allocator
    );
    defer allocator.free(abs_path);
    const is_dir: bool = try file_io_utils.isPathDirectory(abs_path);
    if (is_dir) {
        const files = try file_io_utils.getAllMediaFilesInDirectory(abs_path, allocator);
        media_files.* = files;
    } else {
        // just assign as singleton array. do not append
        media_files.* = .empty;
        const duped = try allocator.dupe(u8, abs_path);
        try media_files.append(allocator, duped);
    }
}

fn mainLoop(
    state: *data_types.AppState,
    allocator: std.mem.Allocator,
    file_path_arg: ?[]const u8
) !void {
    var media_files: std.ArrayList([]const u8) = .empty;
    defer freeMediaFileList(&media_files, allocator);
    var current_file_index: usize = 0;
    var update_media_state: bool = true;

    if (file_path_arg) |path| {
        try setMediaFiles(allocator, path, &media_files);
    }

    var key_pressed: rl.KeyboardKey = .null;

    while (!rl.windowShouldClose()) {
        if (media_files.items.len > 0 and update_media_state) {
            std.log.debug("Loading index: {any}", .{current_file_index});
            std.log.debug("Num files: {any}", .{media_files.items.len});
            try setMediaState(
                state,
                allocator,
                media_files.items[current_file_index]
            );
            update_media_state = false;
        }
        key_pressed = rl.getKeyPressed();

        // TODO: move
        if (key_pressed != .null) {
            std.log.info("Key pressed: {any}", .{key_pressed});
            if (key_pressed == .left) {
                current_file_index = (current_file_index - 1) % media_files.items.len;
                update_media_state = true;
            } else if (key_pressed == .right) {
                current_file_index = (current_file_index + 1) % media_files.items.len;
                update_media_state = true;
            }
        }
        if (rl.isFileDropped()) {
            const dropped = rl.loadDroppedFiles();
            defer rl.unloadDroppedFiles(dropped);

            if (dropped.count > 0) {
                const path = std.mem.span(dropped.paths[0]);
                // Clean up previous state
                if (state.image_state) |*img| image_viewer.unload(img);
                if (state.video_state) |*vid| video_player.close(vid);
                state.image_state = null;
                state.video_state = null;

                state.file_path = path;
                state.media_type = file_io_utils.classifyFile(path);

                switch (state.media_type) {
                    .image => state.image_state = image_viewer.load(path),
                    .video => state.video_state = video_player.open(path),
                    .unknown => std.log.warn("Unknown file type: {s}", .{path}),
                }
            }
        }

        if (ui.drawMenuBar()) |action| {
            switch (action) {
                // for now we just catch the errors. later let's bubble them up
                .open_file => {
                    if (dialog.openFile(allocator) catch null) |path| {
                        defer allocator.free(path);
                        std.log.info("Opening file: {s}", .{path});
                        // load the file using your existing logic
                    }
                },
                .open_folder => {
                    if (dialog.openFolder(allocator) catch null) |path| {
                        defer allocator.free(path);
                        std.log.info("Opening folder: {s}", .{path});
                        // scan directory for media files
                    }
                }

            }
        }

        if (state.video_state) |*vid| {
            video_player.update(vid);
        }

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.init(30, 30, 30, 255));

        switch (state.media_type) {
            .image => {
                if (state.image_state) |*img| {
                    image_viewer.draw(img);
                }
            },
            .video => {
                if (state.video_state) |*vid| {
                    video_player.draw(vid);
                }
            },
            .unknown => {
                ui.drawDropPrompt();
            }
        }

        ui.drawHUD(state);
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    rl.initWindow(
        constants.WINDOW_WIDTH,
        constants.WINDOW_HEIGHT,
        constants.APP_TITLE
    );
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    const file_path: ?[]const u8 = if (args.len > 1) args[1] else null;
    var state = data_types.AppState{
        .allocator = allocator,
        .file_path = file_path,
        .media_type = if (file_path) |p| file_io_utils.classifyFile(p) else .unknown,
    };
    defer {
        if (state.image_state) |*img| image_viewer.unload(img);
        if (state.video_state) |*vid| video_player.close(vid);
    }

    try mainLoop(&state, allocator, file_path);
}
