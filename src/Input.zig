//! Contains the state of the input devices during this frame and offers various utilities.

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
    /// This is a valid state only for 'key_press' events.
    Repeat,
    Release,
};

/// Represents physical keyboard keys. Keys that correspond to ASCII characters have
/// integer values of their respective characters, however you should check if they
/// are printable with 'is_ascii()'.
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

    Space = 32,
    /// The ' key
    Quote = 39,
    /// The , key
    Comma = 44,
    /// The - key
    Minus = 45,
    /// The . key
    Period = 46,
    /// The / key
    Slash = 47,
    /// The ; key
    Semicolon = 59,
    /// The 0 key on the main part of the keyboard
    Digit_0 = 48,
    /// The 1 key on the main part of the keyboard
    Digit_1,
    /// The 2 key on the main part of the keyboard
    Digit_2,
    /// The 3 key on the main part of the keyboard
    Digit_3,
    /// The 4 key on the main part of the keyboard
    Digit_4,
    /// The 5 key on the main part of the keyboard
    Digit_5,
    /// The 6 key on the main part of the keyboard
    Digit_6,
    /// The 7 key on the main part of the keyboard
    Digit_7,
    /// The 8 key on the main part of the keyboard
    Digit_8,
    /// The 9 key on the main part of the keyboard
    Digit_9,
    /// The = key
    Equal = 61,
    A = 65,
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
    /// The [ key
    BracketLeft = 91,
    /// The \ key
    Backslash = 92,
    /// The ] key
    BracketRight = 93,
    /// The ` key
    Backquote = 96,

    F1 = 128,
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
    Numpad_Period,
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

    /// Keys for which this function returns true can be cast to u8 and printed as ASCII characters.
    pub inline fn isAscii(k: Key) bool {
        const value: u8 = @intFromEnum(k);
        return value >= 32 and value <= 126;
    }

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
    /// Usually called mouse button 4 in games
    Back,
    /// Usually called mouse button 5 in games
    Front,
};
