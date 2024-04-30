const std = @import("std");
const crypto = std.crypto;

/// Public constant defining the hash size (data array size for hash storage).
pub const HASH_SIZE: usize = 32;

///
pub const Hash = struct {
    /// An array to store SHA256 hashed output.
    data: [HASH_SIZE]u8,

    /// Default construction of Hash object
    pub fn new() Hash {
        return .{ .data = .{0} ** HASH_SIZE };
    }

    /// Hashing function that takes it's own state (data) and performs a SHA256
    /// hashing alg on it. NOTE: It's planned to have an optional field that will
    /// serve as additional data to hash (if SOME, hasher.update(that_data)....
    pub fn hash(self: *Hash) void {
        // SHA256 Hasher initialization
        var hasher = crypto.hash.sha2.Sha256.init(.{});
        // Updating the hasher with data(to hash)
        hasher.update(&self.data);

        // Getting the hashed data and updating the Hash state with it.
        self.data = hasher.finalResult();
    }
};
