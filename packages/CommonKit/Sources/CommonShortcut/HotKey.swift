import Carbon.HIToolbox
import Foundation

public enum HotKeyError: LocalizedError {
    case unavailable(OSStatus)

    public var errorDescription: String? {
        switch self {
        case .unavailable(let status) where status == eventHotKeyExistsErr:
            "Another app already uses this shortcut."
        case .unavailable(let status):
            "macOS didn't accept this shortcut (error \(status))."
        }
    }
}

/// One system-wide shortcut, through Carbon's RegisterEventHotKey: the only public API that takes a key
/// before the frontmost app sees it without asking for Accessibility or Input Monitoring access.
@MainActor
public final class HotKey {
    public var onPress: (() -> Void)?
    private let id: EventHotKeyID
    private var registration: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private static var count: UInt32 = 0

    /// `signature` is four characters that name the app, such as "CCol"; each instance gets its own
    /// id under it, so an app can hold several shortcuts and each hears only its own.
    public init(signature: String) {
        Self.count += 1
        id = EventHotKeyID(signature: signature.utf8.reduce(0) { $0 << 8 | OSType($1) }, id: Self.count)
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let context = Unmanaged.passUnretained(self).toOpaque()
        // Delivered on the main thread, at key-down, so whatever the shortcut starts starts at once.
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, context in
                guard let event, let context else { return OSStatus(eventNotHandledErr) }
                let hotKey = Unmanaged<HotKey>.fromOpaque(context).takeUnretainedValue()
                var pressed = EventHotKeyID()
                let status = GetEventParameter(
                    event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil,
                    MemoryLayout<EventHotKeyID>.size, nil, &pressed)
                // Another HotKey's press: let it reach that one's handler.
                guard status == noErr, pressed.signature == hotKey.id.signature, pressed.id == hotKey.id.id else {
                    return OSStatus(eventNotHandledErr)
                }
                MainActor.assumeIsolated { hotKey.onPress?() }
                return noErr
            }, 1, &spec, context, &handler)
    }

    public func register(_ combo: KeyCombo) throws {
        unregister()
        let status = RegisterEventHotKey(
            UInt32(combo.keyCode), combo.carbonModifiers, id, GetApplicationEventTarget(), 0, &registration)
        guard status == noErr else {
            registration = nil
            throw HotKeyError.unavailable(status)
        }
    }

    public func unregister() {
        if let registration { UnregisterEventHotKey(registration) }
        registration = nil
    }
}

/// The name a key code types on the current keyboard layout: "Z" on a QWERTZ keyboard's Y key.
public func keyName(_ keyCode: UInt16) -> String? {
    guard let source = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue(),
        let pointer = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
    else { return nil }
    let data = Unmanaged<CFData>.fromOpaque(pointer).takeUnretainedValue() as Data
    return data.withUnsafeBytes { bytes -> String? in
        guard let layout = bytes.baseAddress?.assumingMemoryBound(to: UCKeyboardLayout.self) else { return nil }
        var deadKeys: UInt32 = 0
        var length = 0
        var chars = [UniChar](repeating: 0, count: 4)
        let status = UCKeyTranslate(
            layout, keyCode, UInt16(kUCKeyActionDisplay), 0, UInt32(LMGetKbdType()),
            OptionBits(kUCKeyTranslateNoDeadKeysBit), &deadKeys, chars.count, &length, &chars)
        guard status == noErr, length > 0 else { return nil }
        let name = String(utf16CodeUnits: chars, count: length)
        return name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : name
    }
}

extension KeyCombo {
    /// The shortcut as the menu and Settings show it, on this Mac's keyboard layout.
    public var displayName: String { display(keyName: keyName) }
}
