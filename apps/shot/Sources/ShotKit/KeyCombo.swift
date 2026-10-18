/// A global keyboard shortcut: a virtual key code and its modifiers.
public struct KeyCombo: Codable, Equatable, Sendable {
    public struct Modifiers: OptionSet, Codable, Sendable, Hashable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }

        // The same bits as NSEvent.ModifierFlags, so an event's flags convert with a mask.
        public static let shift = Modifiers(rawValue: 1 << 17)
        public static let control = Modifiers(rawValue: 1 << 18)
        public static let option = Modifiers(rawValue: 1 << 19)
        public static let command = Modifiers(rawValue: 1 << 20)
        public static let all: Modifiers = [.shift, .control, .option, .command]
    }

    public var keyCode: UInt16
    public var modifiers: Modifiers

    public init(keyCode: UInt16, modifiers: Modifiers) {
        self.keyCode = keyCode
        self.modifiers = modifiers.intersection(.all)
    }

    static let two: UInt16 = 19
    /// ⇧⌘2: next to the system's ⇧⌘3, ⇧⌘4, and ⇧⌘5, and free on a stock Mac.
    public static let standard = KeyCombo(keyCode: two, modifiers: [.shift, .command])

    /// The modifier bits Carbon's RegisterEventHotKey takes.
    public var carbonModifiers: UInt32 {
        var flags: UInt32 = 0
        if modifiers.contains(.command) { flags |= 0x0100 }
        if modifiers.contains(.shift) { flags |= 0x0200 }
        if modifiers.contains(.option) { flags |= 0x0800 }
        if modifiers.contains(.control) { flags |= 0x1000 }
        return flags
    }

    /// A shortcut must hold ⌘, ⌥, or ⌃, or it would swallow ordinary typing. Function keys are the exception.
    public var isUsable: Bool {
        !modifiers.isDisjoint(with: [.command, .option, .control]) || Self.functionKeys[keyCode] != nil
    }

    /// "⌥Space", "⌃⇧K". `keyName` reads a character key on the current keyboard layout.
    public func display(keyName: (UInt16) -> String?) -> String {
        var text = ""
        if modifiers.contains(.control) { text += "⌃" }
        if modifiers.contains(.option) { text += "⌥" }
        if modifiers.contains(.shift) { text += "⇧" }
        if modifiers.contains(.command) { text += "⌘" }
        return text + (Self.specialKeys[keyCode] ?? keyName(keyCode)?.uppercased() ?? "Key \(keyCode)")
    }

    /// What `NSMenuItem.keyEquivalent` takes for this key, so a menu shows the shortcut where macOS shows
    /// every other: the lowercased character for a character key, a control character or one of
    /// AppKit's function-key code points otherwise. Nil for a key a menu can't show.
    public func keyEquivalent(keyName: (UInt16) -> String?) -> String? {
        if let scalar = Self.equivalentScalars[keyCode] { return String(Character(UnicodeScalar(scalar)!)) }
        guard Self.specialKeys[keyCode] == nil, let name = keyName(keyCode), name.count == 1 else { return nil }
        return name.lowercased()
    }

    /// AppKit's NSF1FunctionKey and its neighbours, by value, so the model needs no AppKit.
    static let equivalentScalars: [UInt16: UInt32] = [
        122: 0xF704, 120: 0xF705, 99: 0xF706, 118: 0xF707, 96: 0xF708, 97: 0xF709, 98: 0xF70A, 100: 0xF70B,
        101: 0xF70C, 109: 0xF70D, 103: 0xF70E, 111: 0xF70F, 105: 0xF710, 107: 0xF711, 113: 0xF712, 106: 0xF713,
        64: 0xF714, 79: 0xF715, 80: 0xF716, 90: 0xF717,
        123: 0xF702, 124: 0xF703, 125: 0xF701, 126: 0xF700, 115: 0xF729, 119: 0xF72B, 116: 0xF72C, 121: 0xF72D,
        117: 0xF728, 49: 0x20, 36: 0x0D, 76: 0x03, 48: 0x09, 51: 0x08, 53: 0x1B,
    ]

    static let functionKeys: [UInt16: String] = [
        122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6", 98: "F7", 100: "F8", 101: "F9",
        109: "F10", 103: "F11", 111: "F12", 105: "F13", 107: "F14", 113: "F15", 106: "F16", 64: "F17",
        79: "F18", 80: "F19", 90: "F20",
    ]

    /// Keys whose name doesn't depend on the keyboard layout.
    static let specialKeys: [UInt16: String] = functionKeys.merging([
        49: "Space", 36: "↩", 48: "⇥", 51: "⌫", 117: "⌦", 53: "⎋", 123: "←", 124: "→", 125: "↓", 126: "↑",
        115: "↖", 119: "↘", 116: "⇞", 121: "⇟", 76: "⌤",
    ]) { a, _ in a }
}
