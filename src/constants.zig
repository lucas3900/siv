pub const APP_TITLE: [:0]const u8 = "SIV"; // null terminated for C compatibility
pub const WINDOW_WIDTH: u32 = 1280;
pub const WINDOW_HEIGHT: u32 = 720;

pub const IMAGE_EXTENSIONS: [9][]const u8 = .{
    ".png", ".jpg", ".jpeg", ".bmp", ".gif", ".tga", ".hdr", ".psd", ".qoi",
};

pub const VIDEO_EXTENSIONS: [7][]const u8 = .{
    ".mp4", ".mkv", ".avi", ".webm", ".mov", ".flv", ".wmv",
};
