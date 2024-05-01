const std = @import("std");
const crypto = std.crypto;

/// Public constant defining the hash size (data array size for hash storage).
pub const HASH_SIZE: usize = 32;

/// This struct encapsulates the hash data array providing more
/// options/manipulation and flexibility over the actual hash.
pub const Hash = struct {
    /// An array to store SHA256 hashed output.
    data: [HASH_SIZE]u8,

    /// Default construction of Hash object
    pub fn new() Hash {
        return .{ .data = .{0} ** HASH_SIZE };
    }

    /// Hashing function that takes it's own state (data) and performs a SHA256
    /// hashing alg on it. Additionally, if mixin is provided, we hash the both
    /// self data and mixin data.
    pub fn hash(self: *Hash, mixin: ?*const Hash) void {
        // SHA256 Hasher initialization
        var hasher = crypto.hash.sha2.Sha256.init(.{});
        // Updating the hasher with data(to hash)
        hasher.update(&self.data);

        // Checking if mixin is provided, then adding it to the hasher to hash.
        // If not provided we are only hashing self.data
        if (mixin) |val| {
            hasher.update(&val.data);
        }

        // Getting the hashed data and updating the Hash state with it.
        self.data = hasher.finalResult();
    }
};

/// Dummy transactions hasher, since I'm not implementing 'real' transactions
/// (yet), I'm also using a dummy hasher, just providing a random hash.
pub fn hash_transactions(transactions: std.ArrayList(u64)) Hash {
    var hasher = crypto.hash.sha2.Sha256.init(.{});
    for (transactions.items) |item| {
        const bytes = std.mem.toBytes(item);
        hasher.update(&bytes);
    }

    return Hash{ .data = hasher.finalResult() };
}
