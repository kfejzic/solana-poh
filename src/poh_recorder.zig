const std = @import("std");
const Poh = @import("poh.zig").Poh;
const Hash = @import("hash.zig").Hash;
const PohConfig = @import("poh_config.zig").PohConfig;
const Entry = @import("entry.zig").Entry;
const EntryTickHeight = @import("entry.zig").EntryTickHeight;

pub const Slot = u64;

pub const Record = struct {
    mixin: Hash,
    transactions: std.ArrayList(u64),
    slot: Slot,
    // sender: RecordResultSender,

    /// Comment
    pub fn new(
        mixin: Hash,
        transactions: std.ArrayList(u64),
        slot: Slot,
        // sender: RecordResultSender,
    ) Record {
        return Record{
            .mixin = mixin,
            .transactions = transactions,
            .slot = slot,
            // .sender = sender,
        };
    }
};

/// PohRecorder data structure, responsible for creating entries in the poh
pub const PohRecorder = struct {
    /// Poh generator instance
    poh: Poh,
    /// Target ns per tick
    target_ns_per_tick: u64,
    /// Tick height
    tick_height: u64,
    /// --
    leader_first_tick_height_including_grace_ticks: ?u64,
    /// ticks from record
    ticks_from_record: u64,
    /// Cache storing Entries with their respective tick height.
    tick_cache: std.ArrayList(EntryTickHeight),

    /// Default constructor for the PohRecorder struct
    pub fn new(
        last_entry_hash: Hash,
        poh_config: PohConfig,
        target_ns_per_tick: u64,
    ) PohRecorder {
        return PohRecorder{ .poh = Poh.new(last_entry_hash, poh_config.hashes_per_tick, 0), .ticks_from_record = 0, .target_ns_per_tick = target_ns_per_tick, .tick_height = 0, .leader_first_tick_height_including_grace_ticks = 0, .tick_cache = std.ArrayList(EntryTickHeight).init(std.heap.page_allocator) };
    }

    /// Comment fn
    pub fn record(self: *PohRecorder, mixin: Hash, transactions: std.ArrayList(u64)) void {
        if (transactions.items.len == 0)
            std.debug.panic("[PohRecorder::record] Panic! transactions required to be > 0", .{});

        while (true) {
            if (self.poh.record(mixin)) |poh_entry| {
                // std.debug.print("record(): Record.num_hashes: {}, Record.hash: {}\n", .{ rec.num_hashes, rec.hash });
                const entry = Entry{ .num_hashes = poh_entry.num_hashes, .hash = poh_entry.hash, .transactions = transactions };
                _ = entry;
            }

            self.ticks_from_record += 1;
        }
    }

    /// Comment
    pub fn tick(self: *PohRecorder) void {
        if (self.poh.tick()) |poh_entry| {
            const target_time = self.poh.target_poh_time(self.target_ns_per_tick);

            self.tick_height += 1;
            // self.report_poh_timing_point();
            if (self.leader_first_tick_height_including_grace_ticks == null) return;

            const tx = std.ArrayList(u64).init(std.heap.page_allocator);
            self.tick_cache.append(EntryTickHeight{ .entry = Entry{ .num_hashes = poh_entry.num_hashes, .hash = poh_entry.hash, .transactions = tx }, .tick_height = self.tick_height }) catch return;

            while (std.time.nanoTimestamp() < target_time) {
                // TODO busy sleep
            }
        }
    }
};
