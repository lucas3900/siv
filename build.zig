const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // --- raylib-zig dependency ---
    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });
    const raylib = raylib_dep.module("raylib");
    const raygui = raylib_dep.module("raygui");
    const raylib_artifact = raylib_dep.artifact("raylib");

    // Enable JPEG support in raylib (uses stb_image under the hood)
    raylib_artifact.root_module.addCMacro("SUPPORT_FILEFORMAT_JPG", "");

    // --- Main executable ---
    const exe = b.addExecutable(.{
        .name = "siv",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "raylib", .module = raylib },
                .{ .name = "raygui", .module = raygui },
            },
        }),
    });

    exe.linkLibrary(raylib_artifact);

    // Link system FFmpeg libraries for video playback
    // (requires ffmpeg dev headers installed on your system)
    // Uncomment these when you're ready to work on video:
    // exe.root_module.linkSystemLibrary("libavcodec", .{});
    // exe.root_module.linkSystemLibrary("libavformat", .{});
    // exe.root_module.linkSystemLibrary("libavutil", .{});
    // exe.root_module.linkSystemLibrary("libswscale", .{});
    // exe.root_module.linkSystemLibrary("libswresample", .{});
    // exe.root_module.link_libc = true;

    // --- tinyfiledialogs ---
    exe.addCSourceFile(.{
        .file = b.path("lib/tinyfiledialogs.c"),
        .flags = &.{},
    });
    exe.addIncludePath(b.path("lib"));
    exe.root_module.link_libc = true;

    b.installArtifact(exe);

    // --- Run step ---
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    // Allow passing arguments: zig build run -- <path_to_file>
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the media viewer");
    run_step.dependOn(&run_cmd.step);

    // --- Tests ---
    const unit_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "raylib", .module = raylib },
                .{ .name = "raygui", .module = raygui },
            },
        }),
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
