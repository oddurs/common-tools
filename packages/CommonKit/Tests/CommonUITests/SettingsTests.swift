import AppKit
import Testing

@testable import CommonUI

@Suite struct SettingsTests {
    @Test @MainActor func formHeightFitsTheScreen() throws {
        let screen = try #require(NSScreen.main ?? NSScreen.screens.first, "no screen to measure")
        let height = try #require(SettingsWindowHost.fittingHeight(on: screen))
        // Under the menu bar and above the Dock, with the title bar taken off the top.
        #expect(height < screen.visibleFrame.height)
        #expect(height > screen.visibleFrame.height - 40)
        #expect(SettingsWindowHost.fittingHeight(on: nil) == nil)
    }

    @Test @MainActor func loginProblemsReadAsAdvice() {
        let approval = LoginItem.Problem.needsApproval.message
        #expect(approval.hasPrefix("Allow "))
        #expect(approval.hasSuffix(" in System Settings › General › Login Items."))
        #expect(approval.contains(LoginItem.appName))
        #expect(LoginItem.Problem.failed("No.").message == "No.")
        #expect(OpenAtLoginToggle.footnote == "Starts when you log in.")
    }
}
