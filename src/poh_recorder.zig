const std = @import("std");
const Poh = @import("poh.zig").PohMutex;
const Hash = @import("hash.zig").Hash;
const Entry = @import("entry.zig").Entry;
const EntryTickHeight = @import("entry.zig").EntryTickHeight;

pub const Slot = u64;

pub const Record = struct {
    mixin: Hash,
    transactions: std.ArrayList(u64),
    slot: Slot,

    /// Default record constructor
    pub fn new(
        mixin: Hash,
        transactions: std.ArrayList(u64),
        slot: Slot,
    ) Record {
        return Record{
            .mixin = mixin,
            .transactions = transactions,
            .slot = slot,
        };
    }
};

/// PohRecorder data structure, responsible for creating and dispatching entries
/// through the system
pub const PohRecorder = struct {
    /// Poh generator instance
    poh: Poh,
    /// Target ns per tick
    target_ns_per_tick: u64,
    /// Tick height
    tick_height: u64,
    /// ticks from record
    ticks_from_record: u64,
    /// Cache storing Entries with their respective tick height.
    tick_cache: std.ArrayList(EntryTickHeight),

    /// Default constructor for the PohRecorder struct
    pub fn new(
        last_entry_hash: Hash,
        target_ns_per_tick: u64,
        hashes_per_tick: u64,
    ) PohRecorder {
        return PohRecorder{ .poh = Poh.new(last_entry_hash, hashes_per_tick, 0), .ticks_from_record = 0, .target_ns_per_tick = target_ns_per_tick, .tick_height = 0, .tick_cache = std.ArrayList(EntryTickHeight).init(std.heap.page_allocator) };
    }

    /// Creating a pointer to the guarded Poh generator (mutex protected).
    pub fn get_poh_guarded_reference(self: *PohRecorder) *Poh {
        return &self.poh;
    }

    /// Performs recording operation, incorporating the transactions with the
    /// current poh chain, on a succesful poh_entry return, creates an Entry,
    /// dispatching it with in the workingbank entry to the tpu.
    pub fn record(self: *PohRecorder, mixin: Hash, transactions: std.ArrayList(u64)) void {
        if (transactions.items.len == 0)
            std.debug.panic("[PohRecorder::record] Panic! transactions required to be > 0", .{});

        // If a record is created, returns, otherwise perform a tick and
        // increase ticks from record.
        while (true) {
            if (self.poh.record(mixin)) |poh_entry| {
                const entry = Entry{ .num_hashes = poh_entry.num_hashes, .hash = poh_entry.hash, .transactions = transactions };
                _ = entry;
                // Send workingbank entry to transaction processing unit.

                return;
            }

            self.ticks_from_record += 1;
            self.tick();
        }
    }

    /// Performs a tick operation, using the poh generator, if an entry is
    /// created, we store the entry info along with the tich height in tick
    /// cache
    pub fn tick(self: *PohRecorder) void {
        if (self.poh.tick()) |poh_entry| {
            const target_time = self.poh.target_poh_time(self.target_ns_per_tick);

            self.tick_height += 1;
            const tx = std.ArrayList(u64).init(std.heap.page_allocator);
            self.tick_cache.append(EntryTickHeight{ .entry = Entry{ .num_hashes = poh_entry.num_hashes, .hash = poh_entry.hash, .transactions = tx }, .tick_height = self.tick_height }) catch return;

            // Wait for catchup
            while (std.time.nanoTimestamp() < target_time) {
                // TODO busy sleep
            }
        }
    }
};
