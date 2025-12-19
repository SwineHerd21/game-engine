//! Contains handlers for various window events

const Input = @import("Input.zig");
const math = @import("math/math.zig");

pub const Event = union(enum) {
    key_press: KeyEvent,
    key_release: KeyEvent,
    mouse_button_press: MouseButtonEvent,
    mouse_button_release: MouseButtonEvent,
    pointer_motion: PointerMotion,
    // TODO: ? give position on enter/exit
    pointer_enter: void,
    pointer_exit: void,
    focus_gained: void,
    focus_lost: void,
    window_resize: WindowResize,
    window_close: void,
    window_redraw: void,
};

pub const KeyEvent = struct {
    key: Input.Key,
    modifiers: Input.ModifierKeys,
    action: Input.ButtonAction,
};

pub const MouseButtonEvent = struct {
    button: Input.MouseButton,
    modifiers: Input.ModifierKeys,
    action: Input.ButtonAction,
};

pub const PointerMotion = struct {
    /// In pixels, (0, 0) is the top left corner of the window
    position: math.Vec2i,
};

pub const WindowResize = struct {
    width: u32,
    height: u32,
};
