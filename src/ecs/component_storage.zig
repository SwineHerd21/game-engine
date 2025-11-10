const std = @import("std");

const Allocator = std.mem.Allocator;

const Entities = @import("Entities.zig");
const EntityID = Entities.EntityID;

pub fn ComponentStorage(comptime T: type) type {
    return struct {
        hashmap: std.AutoArrayHashMapUnmanaged(EntityID, T),

        const Self = @This();

        pub fn deinit(self: *Self, alloc: Allocator) void {
            var iter = self.hashmap.iterator();
            while (iter.next()) |e| {
                alloc.free(e.key_ptr.*);
            }
            self.hashmap.deinit(alloc);
        }
    };
}

pub const OpaqueComponentStorage = struct {
    ptr: *anyopaque,
    deinit: *const fn(OpaqueComponentStorage, Allocator) void,

    /// Cast inner pointer to 'ComponentStorage(T)'
    pub fn cast(self: OpaqueComponentStorage, comptime T: type) *ComponentStorage(T) {
        return @alignCast(@ptrCast(self.ptr));
    }
};

