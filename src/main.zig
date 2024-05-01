const std = @import("std");
const Hash = @import("hash.zig").Hash;
const PohService = @import("poh_service.zig").PohService;
const PohRecorder = @import("poh_recorder.zig").PohRecorder;
const Channel = @import("channel.zig").Channel;
const TransactionRecorder = @import("poh_service.zig").TransactionRecorder;

pub fn main() !void {
    const time = std.time.nanoTimestamp();
    std.debug.print("Hello World at {}!\n", .{time});

    var exit: std.atomic.Value(bool) = std.atomic.Value(bool).init(false);
    var channel = Channel.new();

    var transactionsRecorder = TransactionRecorder.new(&channel);

    var poh_recorder = PohRecorder.new(Hash.new(), 400000, 100);
    var poh_service = PohService.new(&exit, poh_recorder.get_poh_guarded_reference(), 10, 400000, &channel, &poh_recorder);
    poh_service.start();

    for (0..10) |i| {
        var tx = std.ArrayList(u64).init(std.heap.page_allocator);

        for (0..4) |t| {
            tx.append(t) catch return;
        }

        const sent = transactionsRecorder.record_transaction(i, tx);

        std.debug.print("Record is sent? -> {}!\n", .{sent});
    }

    poh_service.join();
}
