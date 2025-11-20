//! Contains the state of the input devices during this frame and offers various utilities.

const math = @import("math.zig");

const Input = @This();

// TODO: implement the below

/// Current cursor position in window coordinates
pointer_position: math.Vec2i,

pub const ModifierKeys = packed struct {
    shift: bool,
    control: bool,
    alt: bool,
    super: bool,
    caps_lock: bool,
    num_lock: bool,
};

pub const ButtonAction = enum {
    Press,
    /// When a key is being held down keyboards will send repeated key presses.
    /// This is a valid state only for `key_press` events.
    Repeat,
    Release,
};

/// Represents a portable keycode that corresponds to a hardware key location
pub const Key = enum(u8) {
    Unknown = 0,

    Escape,
    Delete,
    Backspace,
    Enter,
    Tab,
    ArrowUp,
    ArrowDown,
    ArrowRight,
    ArrowLeft,
    CapsLock,
    /// The context menu key, usually placed near the right control key.
    Menu,
    Pause,
    PrintScreen,
    ScrollLock,
    Insert,
    Home,
    End,
    PageUp,
    PageDown,

    ShiftLeft,
    ShiftRight,
    ControlLeft,
    ControlRight,
    AltLeft,
    AltRight,
    /// Also known as the Windows/Command key
    SuperLeft,
    /// Also known as the Windows/Command key
    SuperRight,

    Space,
    /// The , key
    Comma,
    /// The . key
    Period,
    /// The ; key
    Semicolon,
    /// The / key
    Slash,
    /// The \ key
    Backslash,
    /// The ' key
    Quote,
    /// The ` key
    Backquote,
    /// The - key
    Minus,
    /// The = key
    Equal,
    /// The [ key
    BracketLeft,
    /// The ] key
    BracketRight,

    @"0",
    @"1",
    @"2",
    @"3",
    @"4",
    @"5",
    @"6",
    @"7",
    @"8",
    @"9",

    A,
    B,
    C,
    D,
    E,
    F,
    G,
    H,
    I,
    J,
    K,
    L,
    M,
    N,
    O,
    P,
    Q,
    R,
    S,
    T,
    U,
    V,
    W,
    X,
    Y,
    Z,

    F1,
    F2,
    F3,
    F4,
    F5,
    F6,
    F7,
    F8,
    F9,
    F10,
    F11,
    F12,
    F13,
    F14,
    F15,
    F16,
    F17,
    F18,
    F19,
    F20,
    F21,
    F22,
    F23,
    F24,

    NumLock,
    Numpad_Decimal,
    Numpad_Divide,
    Numpad_Multiply,
    Numpad_Plus,
    Numpad_Minus,
    Numpad_Enter,
    Numpad_0,
    Numpad_1,
    Numpad_2,
    Numpad_3,
    Numpad_4,
    Numpad_5,
    Numpad_6,
    Numpad_7,
    Numpad_8,
    Numpad_9,

    pub inline fn isShift(k: Key) bool {
        return k == .ShiftLeft or k == .ShiftRight;
    }

    pub inline fn isControl(k: Key) bool {
        return k == .ControlLeft or k == .ControlRight;
    }

    pub inline fn isAlt(k: Key) bool {
        return k == .AltLeft or k == .AltRight;
    }

    pub inline fn isSuper(k: Key) bool {
        return k == .SuperLeft or k == .SuperRight;
    }
};

pub const MouseButton = enum {
    Unknown,
    Left,
    Middle,
    Right,
    WheelUp,
    WheelDown,
    /// Only exists on some mice
    WheelLeft,
    /// Only exists on some mice
    WheelRight,
    /// Usually placed on the side of the mouse and is sometimes called mouse button 4
    Back,
    /// Usually placed on the side of the mouse and is sometimes called mouse button 5
    Front,
};
