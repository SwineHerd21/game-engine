//! Contains the state of the input devices during this frame and offers various utilities.

pub const ButtonState = enum {
    Press,
    Release,
};

pub const KeyModifiers = packed struct {
    shift: bool,
    lock: bool,
    control: bool,
    alt: bool,
    numlock: bool,
    mod3: bool,
    super: bool,
    mod5: bool,
};

/// Represents a keyboard key and its state.
pub const Key = struct {
    keycode: i32,
    modifiers: KeyModifiers,
    state: ButtonState,
};
