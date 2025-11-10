const std = @import("std");

const Allocator = std.mem.Allocator;
const AssetManager = @import("AssetManager.zig");

/// Stores a whole type of assets, knows how to initialize and deinitialize them.
pub fn AssetCache(comptime T: type) type {
    return struct {
        hashmap: std.StringHashMapUnmanaged(T),
        init_fn: *const fn(data: []const u8, *AssetManager) anyerror!T,
        deinit_fn: *const fn(*T, Allocator) void,

        const Self = @This();

        pub fn deinit(self: *Self, alloc: Allocator) void {
            var iter = self.hashmap.iterator();
            while (iter.next()) |e| {
                alloc.free(e.key_ptr.*);
                self.deinit_fn(e.value_ptr, alloc);
            }
            self.hashmap.deinit(alloc);
        }
    };
}

pub const OpaqueAssetCache = struct {
    ptr: *anyopaque,
    deinit: *const fn(OpaqueAssetCache, Allocator) void,

    /// Cast inner pointer to 'AssetCache(T)'
    pub inline fn cast(self: OpaqueAssetCache, comptime T: type) *AssetCache(T) {
        return @alignCast(@ptrCast(self.ptr));
    }
};

test "OpaqueAssetCache cast" {
    var typed_ac: AssetCache(u32) = undefined;
    const opaque_ac: OpaqueAssetCache = .{
        .ptr = @ptrCast(&typed_ac),
        .deinit = (struct {
            fn deinit(_:OpaqueAssetCache, _:Allocator) void {}
        }).deinit,
    };

    try std.testing.expectEqual(&typed_ac, opaque_ac.cast(u32));
}
