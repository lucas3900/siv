const std = @import("std");
const rl = @import("raylib");

const image_viewer = @import("image_viewer.zig");
const video_player = @import("video_player.zig");
const ui = @import("ui.zig");
const data_types = @import("data_types.zig");
const constants = @import("constants.zig");
const file_picker = @import("file_picker.zig");
const file_io_utils = @import("file_io_utils.zig");

fn freeMediaFileList(state: *data_types.AppState) void {
    for (state.media_files.items) |file_path| {
        state.allocator.free(file_path);
    }
    state.media_files.deinit(state.allocator);
    state.media_files = .empty;
}

fn setMediaState(
    state: *data_types.AppState,
    media_path: []const u8
) !void {
    std.log.debug("Setting media state for {s}", .{media_path});
    const abs_path = try file_io_utils.convertPathToAbsolute(
        media_path,
        state.allocator
    );
    defer state.allocator.free(abs_path);
    std.log.debug("Absolute path: {s}", .{abs_path});
    state.media_type = file_io_utils.classifyFile(abs_path);

    if (state.image_state) |*img| image_viewer.unload(img);
    if (state.video_state) |*vid| video_player.close(vid);
    state.image_state = null;
    state.video_state = null;

    switch (state.media_type) {
        .image => state.image_state = image_viewer.load(abs_path),
        .video => state.video_state = video_player.open(abs_path),
        .unknown => std.log.warn("Unknown file type: {s}", .{abs_path}),
    }
}

fn setMediaFiles(state: *data_types.AppState, media_path: []const u8) !void {
    freeMediaFileList(state);
    const abs_path: []const u8 = try file_io_utils.convertPathToAbsolute(
        media_path,
        state.allocator
    );
    defer state.allocator.free(abs_path);
    const is_dir: bool = try file_io_utils.isPathDirectory(abs_path);
    if (is_dir) {
        const files = try file_io_utils.getAllMediaFilesInDirectory(abs_path, state.allocator);
        state.media_files = files;
    } else {
        // just assign as singleton array. do not append
        state.media_files = .empty;
        const duped = try state.allocator.dupe(u8, abs_path);
        try state.media_files.append(state.allocator, duped);
    }
}

fn handleKeyBoardInput(state: *data_types.AppState) void {
    const key_pressed: rl.KeyboardKey = rl.getKeyPressed();
    if (key_pressed != .null) {
        std.log.info("Key pressed: {any}", .{key_pressed});
        // no wrap around
        if (key_pressed == .left) {
            state.current_file_index = if (state.current_file_index == 0) 0 else state.current_file_index - 1;
            state.update_media_state = true;
        } else if (key_pressed == .right) {
            state.current_file_index = @min(state.current_file_index + 1, state.media_files.items.len - 1);
            state.update_media_state = true;
        }
    }
}

fn handleFileDropping(state: *data_types.AppState) !void {
    if (rl.isFileDropped()) {
        const dropped = rl.loadDroppedFiles();
        defer rl.unloadDroppedFiles(dropped);

        if (dropped.count > 0) {
            const path = std.mem.span(dropped.paths[0]);
            try setMediaFiles(state, path);
            state.update_media_state = true;
        }
    }
}

fn handleRenderingMedia(state: *data_types.AppState) void {
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

fn handleFilePicking(state: *data_types.AppState) !void {
    if (ui.drawMenuBar()) |action| {
        switch (action) {
            // for now we just catch the errors. later let's bubble them up
            .open_file => {
                if (file_picker.openFile(state.allocator) catch null) |path| {
                    defer state.allocator.free(path);
                    std.log.info("Opening file: {s}", .{path});
                    try setMediaFiles(state, path);
                }
            },
            .open_folder => {
                if (file_picker.openFolder(state.allocator) catch null) |path| {
                    defer state.allocator.free(path);
                    std.log.info("Opening folder: {s}", .{path});
                    try setMediaFiles(state, path);
                }
            }
        }
    }
}

fn mainLoop(
    state: *data_types.AppState,
    file_path_arg: ?[]const u8
) !void {
    defer freeMediaFileList(state);
    if (file_path_arg) |path| {
        try setMediaFiles(state, path);
    }
    while (!rl.windowShouldClose()) {
        if (state.media_files.items.len > 0 and state.update_media_state) {
            try setMediaState(
                state,
                state.media_files.items[state.current_file_index]
            );
            state.update_media_state = false;
        }
        handleKeyBoardInput(state);
        try handleFileDropping(state);
        handleRenderingMedia(state);
        try handleFilePicking(state);
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
        .allocator = allocator
    };
    defer {
        if (state.image_state) |*img| image_viewer.unload(img);
        if (state.video_state) |*vid| video_player.close(vid);
    }

    try mainLoop(&state, file_path);
}
