const std = @import("std");
const Poh = @import("poh.zig").Poh;
const Hash = @import("hash.zig").Hash;

pub fn main() !void {
    const time = std.time.nanoTimestamp();
    std.debug.print("Hello World at {}!\n", .{time});

    var poh = Poh.new(Hash.new(), 10, null);
    std.debug.print("Hash before: {}\n", .{poh.hash});
    _ = poh.hash_sha256(10);
    std.debug.print("Hash after: {}\n", .{poh.hash});

    // var hash = Hash.default();
    // for (0..10) |_| {
    //     hash.hash();
    //     std.debug.print("{}!\n", .{hash});
    // }
}
