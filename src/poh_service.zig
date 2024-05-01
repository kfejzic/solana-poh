const std = @import("std");
const Hash = @import("hash.zig").Hash;
const PohRecorder = @import("poh_recorder.zig").PohRecorder;
const Record = @import("poh_recorder.zig").Record;
const Slot = @import("poh_recorder.zig").Slot;
const PohConfig = @import("poh_config.zig").PohConfig;
const Poh = @import("poh.zig").Poh;
const Channel = @import("channel.zig").Channel;

/// Comment
pub const PohService = struct {
    /// Working thread handle
    thread: ?std.Thread,
    /// Exit signal
    poh_exit: *std.atomic.Value(bool),
    /// Poh generator reference
    poh: *Poh,
    /// Number of hashes per batch
    hashes_per_batch: u64,
    /// --
    target_ns_per_tick: u64,
    /// Reference(pointer) to a record_receiver, allowing message passing
    /// between threads
    record_receiver: *Channel,
    /// Poh recorder, responsible for creating Entries.
    poh_recorder: *PohRecorder,

    /// Constructor to create a ready to run Poh service.
    pub fn new(poh_exit: *std.atomic.Value(bool), poh: *Poh, hashes_per_batch: u64, target_ns_per_tick: u64, record_receiver: *Channel, poh_recorder: *PohRecorder) PohService {
        return PohService{ .thread = null, .poh_exit = poh_exit, .poh = poh, .hashes_per_batch = hashes_per_batch, .target_ns_per_tick = target_ns_per_tick, .record_receiver = record_receiver, .poh_recorder = poh_recorder };
    }

    /// Responsible for spawning the PohService worker thread and storing it's
    /// handle
    pub fn start(self: *PohService) void {
        const tuple = .{self};
        self.thread = std.Thread.spawn(.{}, tick_producer, tuple) catch null;
    }

    /// Responsible to start and keep the hashing process running in case of
    /// jumput, resulting in woring records in ticks breaks on poh_exit
    fn tick_producer(self: *PohService) void {
        while (!self.poh_exit.load(std.builtin.AtomicOrder.seq_cst)) {
            self.perform_hash();
        }
    }

    /// Performs continuous hashing using Poh.hash_sha256, while checking if the
    /// state is tick ready, then performing a tick or record ready, then
    /// performing a record
    fn perform_hash(self: *PohService) void {
        while (!self.poh_exit.load(std.builtin.AtomicOrder.seq_cst)) {
            // Performing the hash_sha256 continuously hashes_per_batch times
            // (or less, check function doc)
            if (self.poh.hash_sha256(self.hashes_per_batch)) {
                // In case hash_sha256 returns true, we are in  tick ready
                // state. We tick and continue again.
                self.perform_tick();
                continue;
            }
            // In case we are not in a tick ready state we calculate the ideal
            // time to later compare for record checking
            const ideal_time = self.poh.target_poh_time(self.target_ns_per_tick);

            // Checking if the record receiver has a record ready to take, non
            // blocking.
            if (self.record_receiver.has_data()) {
                // If record receiver has a record on it ready to take, we perform a
                // record
                self.perform_record();
                continue;
            }

            // If the ideal time has not yet happened, we wait to match it and
            // check for record existance on the record receiver. (DELAY)
            while (ideal_time > std.time.nanoTimestamp()) {
                // Perform a record if record receiver has data to collect.
                if (self.record_receiver.has_data()) self.perform_record();
            }
        }
    }

    /// Performs a record on poh_recorder using all the available queued
    /// records.
    fn perform_record(self: *PohService) void {
        // Looping until we run out of queued data.
        while (self.record_receiver.has_data()) {
            // Collecting the data from the record receiver
            const record = self.record_receiver.receive();
            // Performing a record over poh_recorder
            self.poh_recorder.record(record.mixin, record.transactions);
        }
    }

    /// Propagating the tick call towards poh_recorder. We can use this function
    /// for time measuring as well.
    fn perform_tick(self: *PohService) void {
        self.poh_recorder.tick();
    }
};

/// Structure that performs transaction recording, providing a way to propagate
/// transactions towards PohService
pub const TransactionRecorder = struct {
    /// Channel that allows communication between threads, allowing
    /// TransactionRecorder to safely propagate Record to PohService for further
    /// manipulation.
    record_sender: *Channel,

    /// Constructor function that allows creating a sender by receiving a
    /// channel reference.
    pub fn new(record_sender: *Channel) TransactionRecorder {
        return TransactionRecorder{ .record_sender = record_sender };
    }

    /// Sends a record, newly created with provided transactions and bank slot to the PohService for further processing.
    pub fn record_transaction(self: *TransactionRecorder, bank_slot: Slot, transactions: std.ArrayList(u64)) void {
        self.record_sender.send(Record.new(Hash.new(transactions), transactions, bank_slot));
    }
};
