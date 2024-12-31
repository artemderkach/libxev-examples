const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const exe = b.addExecutable(.{
        .name = "threads",
        .root_source_file = b.path("threads.zig"),
        .target = target,
        .optimize = optimize,
    });

    const libxev = b.dependency("libxev", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("xev", libxev.module("xev"));

    b.installArtifact(exe);
}
