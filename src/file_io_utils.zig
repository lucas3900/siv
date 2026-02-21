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
        return path;
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
