const Hash = @import("hash.zig").Hash;
const std = @import("std");

const LOW_POWER_MODE: u64 = 300;

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

    /// This function performs a looping hash on it's 'hash' value, creating a
    /// verifiable sequence, as well as updating the inner fields to reflect the
    /// current Pog state. Returning an indicator if the caller needs to tick().
    pub fn hash_sha256(self: *Poh, max_num_hashes: u64) bool {
        // Ensuring that the provided(wanted) number of hashes doesn't exceed the
        // remaining number of hashes.
        // const num_hashes = std.math.min(self.remaining_hashes - 1, max_num_hashes);
        const num_hashes = @min(self.remaining_hashes - 1, max_num_hashes);

        for (0..num_hashes) |_| {
            // Perform the SHA256 hash on its current hash value (Current value
            // being the input), creating a chain/sequence.
            self.hash.hash();
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
};
