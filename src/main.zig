const std = @import("std");
const rl = @import("raylib");

const image_viewer = @import("image_viewer.zig");
const video_player = @import("video_player.zig");
const ui = @import("ui.zig");
const data_types = @import("data_types.zig");
const constants = @import("constants.zig");
const dialog = @import("dialog.zig");
const file_io_utils = @import("file_io_utils.zig");


fn update(
    state: *data_types.AppState,
    allocator: std.mem.Allocator,
) void {
    // Handle file drop
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

    // Update video frame if playing
    if (state.video_state) |*vid| {
        video_player.update(vid);
    }
}

fn initMediaFromPath(
    state: *data_types.AppState,
    path: []const u8,
    allocator: std.mem.Allocator,
) !void {
    const abs_path = try file_io_utils.convertPathToAbsolute(
        path,
        allocator
    );
    defer allocator.free(abs_path);
    std.log.debug("Absolute path: {s}", .{abs_path});
    const is_dir: bool = try file_io_utils.isPathDirectory(abs_path);
    if (is_dir) {
        std.log.debug("Path is a directory", .{});
    } else {
        std.log.debug("Path is a file", .{});
    }

    switch (state.media_type) {
        .image => state.image_state = image_viewer.load(path),
        .video => state.video_state = video_player.open(path),
        .unknown => std.log.warn("Unknown file type: {s}", .{path}),
    }
}

fn mainLoop(state: *data_types.AppState, allocator: std.mem.Allocator) void {
    var key_pressed: rl.KeyboardKey = .null;

    while (!rl.windowShouldClose()) {
        key_pressed = rl.getKeyPressed();
        if (key_pressed != .null) {
            std.log.info("Key pressed: {any}", .{key_pressed});
        }
        update(state, allocator);

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
    // Refactor App
    // If no file path is provided, then open in empty state
    // if file path is provided, then check if it's a directory
    // if it's a single file, then load it
    // if it's a directory, then scan for media files and load the first one
    //   Enable right and left (or maybe vim bindings h and l) to cycle through media files

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
    if (file_path) |p| {
        try initMediaFromPath(&state, p, allocator);
    }

    mainLoop(&state, allocator);

    if (state.image_state) |*img| image_viewer.unload(img);
    if (state.video_state) |*vid| video_player.close(vid);
}
