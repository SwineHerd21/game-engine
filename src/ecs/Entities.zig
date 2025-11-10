const std = @import("std");

const component_storage = @import("component_storage.zig");
const ComponentStorage = component_storage.ComponentStorage;
const OpaqueComponentStorage = component_storage.OpaqueComponentStorage;

const Entities = @This();

pub const EntityID = u64;

gpa: std.mem.Allocator,
entity_count: EntityID,
components: std.StringHashMapUnmanaged(OpaqueComponentStorage),

pub fn init(allocator: std.mem.Allocator) Entities {
    return .{
        .gpa = allocator,
        .entity_count = 0,
        .components = .empty,
    };
}

pub fn deinit(self: *Entities) void {
    var iter = self.components.valueIterator();
    while (iter.next()) |c| {
        c.deinit(c.*, self.gpa);
    }
    self.components.deinit(self.gpa);
}

pub fn new(self: *Entities) EntityID {
    const id = self.entity_count;
    self.entity_count += 1;
    return id;
}

pub fn getComponentPtr(self: Entities, comptime T: type, entity: EntityID) ?*T {
    const opaque_storage = self.components.get(@typeName(T)) orelse return null;
    const storage = opaque_storage.cast(T);
    return storage.hashmap.getPtr(entity);
}

pub fn getComponent(self: Entities, comptime T: type, entity: EntityID) ?T {
    return if (self.getComponentPtr(T, entity)) |ptr| ptr.* else null;
}

pub fn setComponent(self: *Entities, comptime T: type, value: T, entity: EntityID) void {
}
