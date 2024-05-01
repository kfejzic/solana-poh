const std = @import("std");
const Poh = @import("poh.zig").Poh;
const Hash = @import("hash.zig").Hash;
const PohService = @import("poh_service.zig").PohService;
const PohRecorder = @import("poh_recorder.zig").PohRecorder;
const PohConfig = @import("poh_config.zig").PohConfig;
const Channel = @import("channel.zig").Channel;

pub fn main() !void {
    const time = std.time.nanoTimestamp();
    std.debug.print("Hello World at {}!\n", .{time});

    // var poh = Poh.new(Hash.new(), 10, null);
    // std.debug.print("Hash before: {}\n", .{poh.hash});
    // _ = poh.hash_sha256(8);
    // std.debug.print("Hash after: {}\n", .{poh.hash});
    //
    // if (poh.record(poh.hash)) |rec| {
    //     std.debug.print("record(): Record.num_hashes: {}, Record.hash: {}\n", .{ rec.num_hashes, rec.hash });
    // }
    //
    // if (poh.tick()) |rec| {
    //     std.debug.print("tick(): Record.num_hashes: {}, Record.hash: {}\n", .{ rec.num_hashes, rec.hash });
    // }

    // Here
    // (poh_exit: *std.atomic.Bool, poh: *Poh, hashes_per_batch: u64, target_ns_per_tick: u64, record_receiver: *Channel)

    var poh_exit: std.atomic.Value(bool) = std.atomic.Value(bool).init(false);
    var poh = Poh.new(Hash.new(), 100, null);
    const allocator = std.heap.page_allocator;
    var channel = Channel.new(allocator);
    var poh_recorder = PohRecorder.new(Hash.new(), PohConfig{ .hashes_per_tick = 100, .target_tick_duration = 400000 }, 400000);

    var poh_service = PohService.new(&poh_exit, &poh, 1000, 400000, &channel, &poh_recorder);
    poh_service.start();
}
