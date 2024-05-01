/// Comment!
pub const PohConfig = struct {
    /// Target tick rate of the cluster, represented as i128, nano timestamp.
    target_tick_duration: i128,

    /// Number of hashes per tick, if not set, we are entering the LPM (low
    /// power mode), making the validator sleep for target_tick_duration instead
    /// of performing hashes
    hashes_per_tick: ?u64,
};
