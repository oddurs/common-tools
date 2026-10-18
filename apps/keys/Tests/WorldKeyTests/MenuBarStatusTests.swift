import Testing
import WorldKey

struct MenuBarStatusTests {
    let us = MenuBarStatus.Layout(id: "us", flag: "🇺🇸", name: "U.S.")
    let icelandic = MenuBarStatus.Layout(id: "is", flag: "🇮🇸", name: "Icelandic")

    func status(
        trusted: Bool = true, fixing: Bool = true, layout: MenuBarStatus.Layout?, app: String? = "Mail",
        paused: Bool = false, pinned: MenuBarStatus.Layout? = nil
    ) -> MenuBarStatus {
        MenuBarStatus(trusted: trusted, fixing: fixing, layout: layout, app: app, paused: paused, pinned: pinned)
    }

    @Test func fixingShowsTheFlag() {
        let status = status(layout: us)
        #expect(status.look == .working)
        #expect(status.toolTip == "U.S.")
    }

    @Test func aPinnedAppShowsTheLockNotTheDimmedFlag() {
        let status = status(layout: icelandic, pinned: icelandic)
        #expect(status.look == .locked)
        #expect(status.toolTip == "Locked to 🇮🇸 Icelandic in Mail")
    }

    /// Pinning from the menu clears a pause, but Pause Here afterwards keeps the pin, and the app is
    /// still switched to its layout when it comes to the front.
    @Test func aPinnedAppThatIsAlsoPausedStaysLocked() {
        let status = status(layout: us, app: "Ghostty", paused: true, pinned: us)
        #expect(status.look == .locked)
        #expect(status.toolTip == "Locked to 🇺🇸 U.S. in Ghostty · Words left as typed")
    }

    @Test func aPausedAppWithoutAPinIsDimmed() {
        let status = status(layout: us, app: "Ghostty", paused: true)
        #expect(status.look == .dimmed)
        #expect(status.toolTip == "U.S. · Paused in Ghostty")
    }

    @Test func noAccessOrFixingOffDimsEvenAPinnedApp() {
        let untrusted = status(trusted: false, layout: icelandic, pinned: icelandic)
        #expect(untrusted.look == .dimmed)
        #expect(untrusted.toolTip == "Locked to 🇮🇸 Icelandic in Mail · Needs Accessibility access")
        let off = status(fixing: false, layout: us)
        #expect(off.look == .dimmed)
        #expect(off.toolTip == "U.S. · Fixing is paused")
    }

    @Test func switchingAwayFromThePinDropsTheLock() {
        let status = status(layout: us, pinned: icelandic)
        #expect(status.look == .working)
        #expect(status.toolTip == "U.S. · Mail is locked to 🇮🇸 Icelandic")
    }

    @Test func anUnknownLayoutIsDimmed() {
        let status = status(layout: nil, pinned: icelandic)
        #expect(status.look == .dimmed)
        #expect(status.toolTip == "Mail is locked to 🇮🇸 Icelandic")
    }
}
