const Hash = @import("hash.zig").Hash;
const std = @import("std");

const LOW_POWER_MODE: u64 = std.math.maxInt(u64);

/// This struct is a representation of a single entry in the PoH record. Each
/// one of them serving as a verif. timestamp, linking events to keep the order.
pub const PohEntry = struct {
    /// This field showcases the number of hashes that were computed to create
    /// this particular PohEntry, since the last entry, helping to understand the
    /// time that elapsed between 2 entries.
    num_hashes: u64,
    /// This field showcases the hash value for this particular entry,
    /// computated based on the previous PohEntry-hash as input, combined with
    /// additional data.
    hash: Hash,
};

/// This struct is a representation of the state of the PoH generator at any
/// given time.
pub const Poh = struct {
    /// This field stores the current state of the hash chain. SHA256.
    hash: Hash,
    /// This field tracks the total number of hashes that have been computed
    /// since the last tick.
    num_hashes: u64,
    /// This field specifies how many hashes are to be computed between ticks
    /// (frequency of ticks).
    hashes_per_tick: u64,
    /// This field indicates how many more hashes need to be computed before the
    /// next tick takes place.
    remaining_hashes: u64,
    /// This field counts the number of ticks that have occured since the start
    /// of this PoH instance.
    tick_number: u64,
    /// This field holds the starting time of the current slot(Currently
    /// high precision timestamp).
    slot_start_time: i128,

    /// Constructs a new Poh object with provided start hash. Optionally taking
    /// hashes per tick and tick number, if hashes per tick are not provided low
    /// power mode is used. In case of tick number being left out, zero is used
    /// (clear/new state).
    pub fn new(hash_value: Hash, hashes_per_tick: ?u64, tick_number: ?u64) Poh {
        // Taking either the provided hashes per tick or low power mode in case
        // of hashes per tick being null (not provided).
        const hashes_pt = hashes_per_tick orelse LOW_POWER_MODE;
        // Ensuring hashes per tick is greater than 1, otherwise panic.
        if (hashes_pt <= 1) std.debug.panic("[Poh::new] Panic! hashes_per_tick required to be > 1", .{});

        // Returning a new Poh object with stot start_time being set to now(),
        // high precision nanotimestamp.
        return Poh{ .hash = hash_value, .num_hashes = 0, .hashes_per_tick = hashes_pt, .remaining_hashes = hashes_pt, .tick_number = tick_number orelse 0, .slot_start_time = std.time.nanoTimestamp() };
    }

    /// Returns the ideal time from target ns per tick.
    pub fn target_poh_time(self: *Poh, target_ns_per_tick: u64) i128 {
        if (self.hashes_per_tick < 1) std.debug.panic("[Poh::target_poh_time] Panic! hashes_per_tick required to be > 1", .{});

        const offset_tick_ns = target_ns_per_tick * self.tick_number;
        const offset_ns = target_ns_per_tick * self.num_hashes / self.hashes_per_tick;
        return self.slot_start_time + offset_ns + offset_tick_ns;
    }

    /// This function performs a looping hash on it's 'hash' value, creating a
    /// verifiable sequence, as well as updating the inner fields to reflect the
    /// current Pog state. Returning an indicator if the caller needs to tick().
    pub fn hash_sha256(self: *Poh, max_num_hashes: u64) bool {
        // Ensuring that the provided(wanted) number of hashes doesn't exceed the
        // remaining number of hashes.
        const num_hashes = @min(self.remaining_hashes - 1, max_num_hashes);

        for (0..num_hashes) |_| {
            // Perform the SHA256 hash on its current hash value (Current value
            // being the input), creating a chain/sequence.
            self.hash.hash(null);
        }

        // Updating the fields to reflect the current(new) state
        self.num_hashes += num_hashes;
        self.remaining_hashes -= num_hashes;

        // Ensuring that the remmaining hashes count stays above 0, showcasing a
        // healthy state of Poh.
        if (self.remaining_hashes <= 0) std.debug.panic("[Poh::hash] Panic! remaining_hashes required to be > 0", .{});
        // Returning true if case the remaining hashes comes to 1, requiring a
        // tick()
        return self.remaining_hashes == 1;
    }

    /// This function records an event by taking a piece of data(event) 'mixin', and
    /// incorporating it into the ongoiong PoH sequence/chain, This ensures that
    /// every event is linked to the history of all previous entries.
    pub fn record(self: *Poh, mixin: Hash) ?PohEntry {
        // Ensuring that we are not in the 'tick ready' state.
        if (self.remaining_hashes == 1) return null;

        // Performing a hash by hashing current poh combined with mixin.
        self.hash.hash(&mixin);
        const num_hashes = self.num_hashes + 1;
        // Reseting the num_hashes since a record is created, but leaving the
        // remaining_hashes in tact (just decrement) to ensure tick happens as regular.
        self.num_hashes = 0;
        self.remaining_hashes -= 1;

        return PohEntry{ .num_hashes = num_hashes, .hash = self.hash };
    }

    /// This function generates a new PohEntry that represents a tick in the poh
    /// sequence, when no external data are incorporated, used for timekeeping.
    pub fn tick(self: *Poh) ?PohEntry {
        // Perform the final hash of the poh sequence and update the Poh state
        // to reflect that
        self.hash.hash(null);
        self.num_hashes += 1;
        self.remaining_hashes -= 1;

        // Checking if we are in low power mode and the state of our remaining
        // hashes is 0, since a record is created if we're in LPM, or there are
        // no remaining hashes left.
        if (self.hashes_per_tick != LOW_POWER_MODE and self.remaining_hashes != 0)
            return null;

        // Save the current state (snapshot) of the Poh for record purposes.
        const num_hashes = self.num_hashes;
        // Reset remaining_hashes to the initial value for a new tick flow.
        self.remaining_hashes = self.hashes_per_tick;
        self.tick_number += 1;

        return PohEntry{ .num_hashes = num_hashes, .hash = self.hash };
    }
};
