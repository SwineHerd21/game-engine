//! Contains handlers for various window events

const std = @import("std");

pub const Event = union(enum) {
    key_press: KeyPress,
    key_release: KeyRelease,
    mousebutton_press: MouseButtonPress,
    mousebutton_release: MouseButtonRelease,
    pointer_move: PointerMove,
    pointer_enter: PointerEnter,
    pointer_exit: PointerExit,
    focus_gain: FocusGain,
    focus_lose: FocusLoss,
    window_resize: WindowResize,
    window_close: WindowClose,
};

pub const KeyModifiers = packed struct {
    shift: bool,
    ctrl: bool,
    alt: bool,
    super: bool,
};

pub const KeyPress = struct {
    keycode: u8,
    modifiers: KeyModifiers,
};

pub const KeyRelease = struct {
    keycode: u8,
    modifier: KeyModifiers,
};

pub const MouseButtonPress = struct {
    button: u8,
};

pub const MouseButtonRelease = struct {
    button: u8,
};

pub const PointerMove = struct {
    x: i32,
    y: i32,
};

pub const PointerEnter = struct {
    //
};

pub const PointerExit = struct {
    //
};

pub const FocusGain = struct {
    //
};

pub const FocusLoss = struct {
    //
};

pub const WindowResize = struct {
    width: i32,
    height: i32,
};

pub const WindowClose = struct {
    //
};
