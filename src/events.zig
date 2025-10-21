//! Contains handlers for various window events

const std = @import("std");

pub fn handleKeyPress() void {
    std.debug.print("ASD ", .{});
}

pub fn handleKeyRelease() void {
    std.debug.print("DSA ", .{});
}

pub fn handlePointerButtonPress() void {
    std.debug.print("mouse ", .{});
}

pub fn handlePointerButtonRelease() void {
    std.debug.print("esuom ", .{});
}

pub fn handlePointerMotion() void {
    std.debug.print("m", .{});
}

pub fn handlePointerEnter() void {
    std.debug.print("entered ", .{});
}

pub fn handlePointerExit() void {
    std.debug.print("exited ", .{});
}

pub fn handleGainFocus() void {
    std.debug.print("focused ", .{});
}

pub fn handleLoseFocus() void {
    std.debug.print("unfocused ", .{});
}
