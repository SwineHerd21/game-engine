const std = @import("std");

const component_storage = @import("component_storage.zig");
const ComponentStorage = component_storage.ComponentStorage;
const OpaqueComponentStorage = component_storage.OpaqueComponentStorage;

const Entities = @This();

pub const EntityID = u64;

// TODO: decide how to do this

gpa: std.mem.Allocator,
entity_count: EntityID,

pub fn init(allocator: std.mem.Allocator) Entities {
    return .{
        .gpa = allocator,
        .entity_count = 0,
    };
}


