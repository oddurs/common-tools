import AppKit
import CommonUI
import SwiftUI

/// Click, then press the new shortcut. Escape cancels, Delete restores `standard`. While it records,
/// `suspend` runs, so the old shortcut doesn't fire; `resume` runs when it stops, to register
/// whatever `combo` is then.
public struct ShortcutRecorder: View {
    @Binding var combo: KeyCombo
    let standard: KeyCombo
    let suspend: () -> Void
    let resume: () -> Void
    @State private var recording = false
    @State private var monitor: Any?
    @State private var hint: String?

    public init(
        combo: Binding<KeyCombo>, standard: KeyCombo, suspend: @escaping () -> Void, resume: @escaping () -> Void
    ) {
        _combo = combo
        self.standard = standard
        self.suspend = suspend
        self.resume = resume
    }

    public var body: some View {
        HStack(spacing: Tokens.Space.xs) {
            if let hint { SettingsFootnote(hint) }
            Button {
                recording ? stop() : start()
            } label: {
                Text(recording ? "Type Shortcut…" : combo.displayName)
                    .monospacedDigit()
                    // Wide enough for "Type Shortcut…", so the button holds still while it records.
                    .frame(minWidth: 110)
            }
        }
        .onDisappear { stop() }
    }

    private func start() {
        suspend()
        recording = true
        hint = nil
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let keyCode = event.keyCode
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue
            MainActor.assumeIsolated { record(keyCode: keyCode, flags: flags) }
            // Swallowed, so the key doesn't also reach the Settings window.
            return nil
        }
    }

    private func record(keyCode: UInt16, flags: UInt) {
        switch keyCode {
        case 53:  // Escape
            stop()
        case 51, 117:  // Delete, Forward Delete
            combo = standard
            stop()
        default:
            let candidate = KeyCombo(keyCode: keyCode, modifiers: KeyCombo.Modifiers(rawValue: flags))
            guard candidate.isUsable else {
                hint = "Add ⌘, ⌥, or ⌃"
                return
            }
            combo = candidate
            stop()
        }
    }

    private func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        guard recording else { return }
        recording = false
        hint = nil
        resume()
    }
}
