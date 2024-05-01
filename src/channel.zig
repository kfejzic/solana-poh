const std = @import("std");
const Record = @import("poh_recorder.zig").Record;

/// Message sharing channel, designed to mimic a concurrent queue, providing
/// support for sending and receiving Records between threads.
///
/// Very simple and time limited implementation that could be improved upon both
/// using inproc and zig's low level abilities!
pub const Channel = struct {
    /// Field representing the state of queue, true for editing phase
    /// (sending), false for free to take and check
    locked: std.atomic.Value(bool),
    /// Field representing if a value has been sent since last receive (if len >
    /// 0)
    data: std.atomic.Value(bool),
    /// Data storage collection
    queue: std.ArrayList(Record),

    /// Constructs a new Channel with an allocator provided.
    pub fn new() Channel {
        return Channel{ .locked = std.atomic.Value(bool).init(false), .data = std.atomic.Value(bool).init(false), .queue = std.ArrayList(Record).init(std.heap.page_allocator) };
    }

    /// Provides an option for sending records by checking if the state edit is
    /// locked (data manipulated by other source), then aquiring the lock and
    /// editing data, at the end releasing the lock and activating the state
    pub fn send(self: *Channel, record: Record) bool {
        while (self.locked.load(std.builtin.AtomicOrder.seq_cst)) {} // Wait to aquire state edit

        self.locked.store(true, std.builtin.AtomicOrder.seq_cst);
        self.queue.append(record) catch return false;
        std.debug.print("Size: {}!\n", .{self.queue.items.len});
        self.locked.store(false, std.builtin.AtomicOrder.seq_cst);
        self.data.store(true, std.builtin.AtomicOrder.seq_cst);

        return true;
    }

    /// Provides an option for receiving records by checking if the state is
    /// active(data), if yes and it's not locked we can aquire the lock and take the first
    /// value in queue. We update te has_data state to false if that was the only
    /// value available.
    pub fn receive(self: *Channel) Record {
        // Wait to active state and free lock
        while (!self.data.load(std.builtin.AtomicOrder.seq_cst) or self.locked.load(std.builtin.AtomicOrder.seq_cst)) {
            // TODO busy sleep
        }

        self.locked.store(true, std.builtin.AtomicOrder.seq_cst);
        const rec = self.queue.orderedRemove(0);
        std.debug.print("Size: {}!\n", .{self.queue.items.len});
        if (self.queue.items.len == 0) self.data.store(false, std.builtin.AtomicOrder.seq_cst);
        self.locked.store(false, std.builtin.AtomicOrder.seq_cst);

        return rec;
    }

    /// Provides information if there's an active state (Record to take), to
    /// avoid waiting if not.
    pub fn has_data(self: *Channel) bool {
        return self.data.load(std.builtin.AtomicOrder.seq_cst);
    }
};
