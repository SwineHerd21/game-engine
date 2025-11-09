const std = @import("std");

const Allocator = std.mem.Allocator;

pub fn AssetCache(comptime T: type) type {
    return struct {
        hashmap: std.StringHashMapUnmanaged(T),
        init_fn: *const fn(data: []const u8, Allocator) T,
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
    pub fn cast(self: OpaqueAssetCache, comptime T: type) *AssetCache(T) {
        return @alignCast(@ptrCast(self.ptr));
    }
};
