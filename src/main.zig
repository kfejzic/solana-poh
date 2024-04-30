const std = @import("std");
const Poh = @import("poh.zig").Poh;
const Hash = @import("hash.zig").Hash;

pub fn main() !void {
    const time = std.time.nanoTimestamp();
    std.debug.print("Hello World at {}!\n", .{time});

    var poh = Poh.new(Hash.new(), 10, null);
    std.debug.print("Hash before: {}\n", .{poh.hash});
    _ = poh.hash_sha256(8);
    std.debug.print("Hash after: {}\n", .{poh.hash});

    if (poh.record(poh.hash)) |rec| {
        std.debug.print("record(): Record.num_hashes: {}, Record.hash: {}\n", .{ rec.num_hashes, rec.hash });
    }

    if (poh.tick()) |rec| {
        std.debug.print("tick(): Record.num_hashes: {}, Record.hash: {}\n", .{ rec.num_hashes, rec.hash });
    }
}
