//! Contains the state of the input devices during this frame and offers various utilities.

pub const Key = struct {
    keycode: u8,
    modifiers: KeyModifiers,
};

pub const PointerButton = struct {
    button: u8,
};

pub const KeyModifiers = packed struct {
    shift: bool,
    control: bool,
    alt: bool,
    super: bool,
    caps_lock: bool,
    num_lock: bool,
};

