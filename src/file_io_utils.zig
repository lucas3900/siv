const std = @import("std");
const constants = @import("constants.zig");
const data_types = @import("data_types.zig");

pub fn isPathDirectory(path: []const u8) !bool {
    var file = try std.fs.openFileAbsolute(path, .{});
    defer file.close();

    const stat = try file.stat();
    // TODO: sym links maybe?
    switch (stat.kind) {
        .directory => return true,
        else => return false
    }
}

pub fn convertPathToAbsolute(path: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    if (std.fs.path.isAbsolute(path)) {
        std.log.debug("Path is absolute: {s}\n", .{path});
        return try allocator.dupe(u8, path);  // Duplicate so caller can always free
    }

    const cwd_path = try std.fs.cwd().realpathAlloc(allocator, ".");
    defer allocator.free(cwd_path);

    std.log.debug("Path is not absolute: {s}\n", .{path});
    return std.fs.path.resolve(allocator, &.{cwd_path, path});
}

pub fn listAllFilesInDirectory(path: []const u8, allocator: std.mem.Allocator) ![]std.fs.Dir.Entry {
    var dir = try std.fs.openDirAbsolute(path, .{});
    defer dir.close();

    var files = std.ArrayList(std.fs.Dir.Entry).init(allocator);
    try files.appendSlice(try dir.readDirAlloc(allocator, .{}));
    return files.toOwnedSlice();
}


pub fn classifyFile(path: []const u8) data_types.MediaType {
    const ext = std.fs.path.extension(path);
    for (constants.IMAGE_EXTENSIONS) |ie| {
        if (std.mem.eql(u8, ext, ie)) return .image;
    }
    for (constants.VIDEO_EXTENSIONS) |ve| {
        if (std.mem.eql(u8, ext, ve)) return .video;
    }
    return .unknown;
}

pub fn getAllMediaFilesInDirectory(
    path: []const u8,
    allocator: std.mem.Allocator
) !std.ArrayList([]const u8) {
    std.log.debug("Getting all media files in directory: {s}\n", .{path});
    var dir = try std.fs.openDirAbsolute(path, .{ .iterate = true });
    defer dir.close();

    var paths: std.ArrayList([]const u8) = .empty;

    var walker = try dir.walk(allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        if (entry.kind == .file) {
            const media_type = classifyFile(entry.path);
            if (media_type != .unknown) {
                // concatenate directory and path
                const full_path = try std.fs.path.join(allocator, &.{path, entry.path});
                defer allocator.free(full_path);
                const duped = try allocator.dupe(u8, full_path);
                try paths.append(allocator, duped);
            }
        }
    }

    return paths;
}
