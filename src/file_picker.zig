const std = @import("std");

const image_filters = [_][*:0]const u8{
    "*.png", "*.jpg", "*.jpeg", "*.bmp",
    "*.gif", "*.tga", "*.hdr",
};

const video_filters= [_][*:0]const u8{
    "*.mp4", "*.mkv", "*.avi", "*.webm",
    "*.mov", "*.flv",
};

// Zenity implementaiton. it's slow an sucks

pub fn openFile(allocator: std.mem.Allocator) !?[]const u8 {
    const result = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{
            "zenity",
            "--file-selection",
            "--title=Open File",
            "--file-filter=Media Files | *.png *.jpg *.jpeg *.bmp *.gif *.mp4 *.mkv *.avi *.webm *.mov",
        },
    });
    defer allocator.free(result.stderr);

    if (result.term.Exited == 0) {
        const trimmed = std.mem.trimRight(u8, result.stdout, "\n");
        const path = try allocator.dupe(u8, trimmed);
        allocator.free(result.stdout); // free the original full allocation
        return path;
    }

    allocator.free(result.stdout);
    return null; // user cancelled
}

pub fn openFolder(allocator: std.mem.Allocator) !?[]const u8 {
    const result = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{
            "zenity",
            "--file-selection",
            "--directory",
            "--title=Open Folder",
        },
    });
    defer allocator.free(result.stderr);

    if (result.term.Exited == 0) {
        const trimmed = std.mem.trimRight(u8, result.stdout, "\n");
        const path = try allocator.dupe(u8, trimmed);
        allocator.free(result.stdout); // free the original full allocation
        return path;
    }

    // User cancelled — free stdout since nobody needs it
    allocator.free(result.stdout);
    return null;
}
