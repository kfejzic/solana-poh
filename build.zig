const std = @import("std");

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "solana-poh",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = b.host,
    });

    b.installArtifact(exe);
}
