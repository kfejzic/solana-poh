const std = @import("std");
const Hash = @import("hash.zig").Hash;

/// COmment
pub const Entry = struct {
    /// The number of hashes since the previous Entry ID.
    num_hashes: u64,

    /// The SHA-256 hash `num_hashes` after the previous Entry ID.
    hash: Hash,

    /// An unordered list of transactions that were observed before the Entry ID was
    /// generated. They may have been observed before a previous Entry ID but were
    /// pushed back into this list to ensure deterministic interpretation of the ledger.
    transactions: std.ArrayList(u64),
};

/// Struct representing a pair, holding Entry and it's tick height for tick
/// caching purposes in Poh Recorder.
pub const EntryTickHeight = struct {
    entry: Entry,
    tick_height: u64,
};
