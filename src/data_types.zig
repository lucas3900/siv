const rl = @import("raylib");
const std = @import("std");
const c = @cImport({
    @cInclude("libavcodec/avcodec.h");
    @cInclude("libavformat/avformat.h");
    @cInclude("libavutil/avutil.h");
    @cInclude("libavutil/imgutils.h");
    @cInclude("libswscale/swscale.h");
});


pub const MediaType = enum {
    image,
    video,
    unknown,
};

pub const ImageState = struct {
    texture: rl.Texture2D,
    width: i32,
    height: i32,
    zoom: f32 = 1.0,
    offset_x: f32 = 0.0,
    offset_y: f32 = 0.0,
};

pub const VideoState = struct {
    // FFmpeg state
    fmt_ctx: *c.AVFormatContext,
    codec_ctx: *c.AVCodecContext,
    sws_ctx: ?*c.SwsContext,
    video_stream_idx: usize,

    // Decoding buffers
    packet: *c.AVPacket,
    frame: *c.AVFrame,
    frame_rgb: *c.AVFrame,
    rgb_buffer: []u8,

    // Raylib display
    texture: rl.Texture2D,
    width: i32,
    height: i32,

    // Playback
    playing: bool = false,
    finished: bool = false,
    frame_time: f64 = 0.0,
    time_base: f64 = 0.0,
    last_pts: i64 = 0,
    clock: f64 = 0.0,
};

pub const AppState = struct {
    allocator: std.mem.Allocator,
    media_files: std.ArrayList([]const u8) = .empty,
    current_file_index: usize = 0,
    update_media_state: bool = true,
    media_type: MediaType = .unknown,
    image_state: ?ImageState = null,
    video_state: ?VideoState = null,
};
