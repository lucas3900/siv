const std = @import("std");
const rl = @import("raylib");
const data_types = @import("data_types.zig");

// FFmpeg C imports — linked via build.zig system libraries
const c = @cImport({
    @cInclude("libavcodec/avcodec.h");
    @cInclude("libavformat/avformat.h");
    @cInclude("libavutil/avutil.h");
    @cInclude("libavutil/imgutils.h");
    @cInclude("libswscale/swscale.h");
});


pub fn open(path: []const u8) ?data_types.VideoState {
    _ = path;
    // TODO: Implement FFmpeg video opening
    //
    // The full implementation involves:
    // 1. avformat_open_input() to open the file
    // 2. avformat_find_stream_info() to read stream info
    // 3. Find the video stream index
    // 4. Get the codec and open a decoder with avcodec_open2()
    // 5. Allocate frames (raw + RGB) and a packet
    // 6. Set up SwsContext for pixel format conversion to RGB24
    // 7. Create a raylib Texture2D to upload decoded frames to
    //
    // This is the most complex part of the project. Start with
    // image viewing first, then come back to this.
    //
    // See: https://github.com/allyourcodebase/ffmpeg for the
    // Zig-native FFmpeg package, or link system ffmpeg as we do
    // in build.zig.

    std.log.info("Video playback not yet implemented — start with images!", .{});
    return null;
}

pub fn close(_: *data_types.VideoState) void {
    // Free FFmpeg resources in reverse order
    //_ = state;
    // TODO: avcodec_free_context, avformat_close_input, etc.
}

pub fn update(state: *data_types.VideoState) void {
    if (!state.playing or state.finished) return;

    // TODO: Decode next frame
    // 1. av_read_frame() to get next packet
    // 2. avcodec_send_packet() + avcodec_receive_frame()
    // 3. sws_scale() to convert to RGB24
    // 4. rl.updateTexture() to upload pixels to GPU
    // 5. Sync to frame timing using PTS and time_base
}

pub fn draw(state: *data_types.VideoState) void {
    // Same fit-to-window logic as image_viewer
    const win_w: f32 = @floatFromInt(rl.getScreenWidth());
    const win_h: f32 = @floatFromInt(rl.getScreenHeight());
    const vid_w: f32 = @floatFromInt(state.width);
    const vid_h: f32 = @floatFromInt(state.height);

    const scale = @min(win_w / vid_w, win_h / vid_h);
    const draw_w = vid_w * scale;
    const draw_h = vid_h * scale;
    const x = (win_w - draw_w) / 2.0;
    const y = (win_h - draw_h) / 2.0;

    rl.drawTexturePro(
        state.texture,
        .{ .x = 0, .y = 0, .width = vid_w, .height = vid_h },
        .{ .x = x, .y = y, .width = draw_w, .height = draw_h },
        .{ .x = 0, .y = 0 },
        0.0,
        rl.Color.white,
    );
}
