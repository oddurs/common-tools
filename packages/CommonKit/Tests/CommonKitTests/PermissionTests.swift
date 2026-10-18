import Foundation
import Testing

@testable import CommonKit

@Suite struct PermissionTests {
    /// Records what would have run, and never runs it.
    final class Recorder: @unchecked Sendable {
        var calls: [(String, [String])] = []
        var status: Int32 = 0
        var runner: Permission.Runner {
            { [self] executable, arguments in
                calls.append((executable.path, arguments))
                return status
            }
        }
    }

    @Test func resetClearsOnlyThisAppsRecordOfThisService() throws {
        let recorder = Recorder()
        try Permission.screenRecording(reason: "").reset(bundleID: "com.oddurs.commonshot", run: recorder.runner)
        try Permission.accessibility(reason: "").reset(bundleID: "com.oddurs.commonkeys", run: recorder.runner)
        #expect(recorder.calls.map(\.0) == ["/usr/bin/tccutil", "/usr/bin/tccutil"])
        #expect(
            recorder.calls.map(\.1) == [
                ["reset", "ScreenCapture", "com.oddurs.commonshot"],
                ["reset", "Accessibility", "com.oddurs.commonkeys"],
            ])
    }

    @Test func aFailedResetSaysSo() {
        let recorder = Recorder()
        recorder.status = 70
        #expect(throws: Permission.ResetError.failed(status: 70)) {
            try Permission.accessibility(reason: "").reset(bundleID: "com.example", run: recorder.runner)
        }
    }

    @Test func noBundleIdentifierRunsNothing() {
        let recorder = Recorder()
        #expect(throws: Permission.ResetError.noBundleIdentifier) {
            try Permission.accessibility(reason: "").reset(bundleID: nil, run: recorder.runner)
        }
        #expect(recorder.calls.isEmpty)
    }

    @Test func onlyScreenRecordingWaitsForAReopen() {
        let shot = Permission.screenRecording(reason: "")
        let keys = Permission.accessibility(reason: "")
        #expect(
            shot.staleSwitchNote(app: "Common Shot")
                == "If Common Shot is already on in System Settings, that switch belongs to an earlier copy.")
        #expect(shot.reopenNote(app: "Common Shot") == "macOS applies the switch only after Common Shot reopens.")
        #expect(keys.reopenNote(app: "Common Keys") == nil)
    }

    @Test func relaunchWaitsForThisProcessThenOpensTheBundle() {
        let command = Relaunch.command(bundle: URL(fileURLWithPath: "/Applications/Common Shot.app"), pid: 4242)
        #expect(command.executable.path == "/bin/sh")
        #expect(command.arguments.dropFirst(2) == ["4242", "/Applications/Common Shot.app"])
        // The path reaches the script as $1, never spliced into it, so a space can't split it.
        #expect(!command.arguments[1].contains("Common Shot"))
        #expect(command.arguments[1].contains(#"open -n "$1""#))
    }
}
