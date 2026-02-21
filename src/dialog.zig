const std = @import("std");

const c = @cImport({
    @cInclude("tinyfiledialogs.h");
});

const image_filters = [_][*:0]const u8{
    "*.png", "*.jpg", "*.jpeg", "*.bmp",
    "*.gif", "*.tga", "*.hdr",
};

const video_filters= [_][*:0]const u8{
    "*.mp4", "*.mkv", "*.avi", "*.webm",
    "*.mov", "*.flv",
};

pub fn openFile() ?[]const u8 {
    const all_filters = image_filters ++ video_filters;
    const result = c.tinyfd_openFileDialog(
        "Open File",           // title
        "",                    // default path
        all_filters.len,       // number of filter patterns
        &all_filters,          // filter patterns
        "Media Files",         // filter description
        0,                     // single select
    );
    if (result) |path| {
        return std.mem.span(path);
    }
    return null;
}

pub fn openFolder() ?[]const u8 {
    const result = c.tinyfd_selectFolderDialog(
        "Open Folder",  // title
        "",             // default path
    );
    if (result) |path| {
        return std.mem.span(path);
    }
    return null;
}

// Zenity implementaiton

// pub fn openFile(allocator: std.mem.Allocator) !?[]const u8 {
//     const result = try std.process.Child.run(.{
//         .allocator = allocator,
//         .argv = &.{
//             "zenity",
//             "--file-selection",
//             "--title=Open File",
//             "--file-filter=Media Files | *.png *.jpg *.jpeg *.bmp *.gif *.mp4 *.mkv *.avi *.webm *.mov",
//         },
//     });
//     defer allocator.free(result.stderr);
// 
//     if (result.term.Exited == 0) {
//         // zenity returns the path with a trailing newline
//         const path = std.mem.trimRight(u8, result.stdout, "\n");
//         // Caller owns the memory (result.stdout)
//         return path;
//     }
// 
//     allocator.free(result.stdout);
//     return null; // user cancelled
// }
// 
// pub fn openFolder(allocator: std.mem.Allocator) !?[]const u8 {
//     const result = try std.process.Child.run(.{
//         .allocator = allocator,
//         .argv = &.{
//             "zenity",
//             "--file-selection",
//             "--directory",
//             "--title=Open Folder",
//         },
//     });
//     defer allocator.free(result.stderr);
// 
//     if (result.term.Exited == 0) {
//         const path = std.mem.trimRight(u8, result.stdout, "\n");
//         return path;
//     }
// 
//     allocator.free(result.stdout);
//     return null;
// }
