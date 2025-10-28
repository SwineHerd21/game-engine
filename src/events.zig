//! Contains handlers for various window events

const input = @import("Input.zig");

pub const Event = union(enum) {
    key_press: input.Key,
    key_release: input.Key,
    pointer_button_press: input.PointerButton,
    pointer_button_release: input.PointerButton,
    pointer_motion: @Vector(2, i32),
    // TODO: ? give position on enter/exit
    pointer_enter: void,
    pointer_exit: void,
    focus_gained: void,
    focus_lost: void,
    window_resize: WindowResize,
    window_close: void,
};

const WindowResize = struct {
    width: u32,
    height: u32,
};
