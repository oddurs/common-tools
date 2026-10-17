import AppKit

/// Quits the app and opens it again: how a Screen Recording switch turned on while the app runs
/// takes effect, since macOS reads it only when the app starts.
@MainActor
public enum Relaunch {
    /// A shell that waits for `pid` to exit, then opens `bundle` again. It outlives the app, so the
    /// app can quit first; opening before it has gone would only bring the old copy forward.
    nonisolated static func command(bundle: URL, pid: Int32) -> (executable: URL, arguments: [String]) {
        (
            URL(fileURLWithPath: "/bin/sh"),
            [
                "-c", #"while kill -0 "$0" 2>/dev/null; do sleep 0.2; done; exec /usr/bin/open -n "$1""#,
                String(pid), bundle.path,
            ]
        )
    }

    /// Starts the waiting shell, then quits.
    public static func now() throws {
        let command = command(bundle: Bundle.main.bundleURL, pid: ProcessInfo.processInfo.processIdentifier)
        let process = Process()
        process.executableURL = command.executable
        process.arguments = command.arguments
        try process.run()
        NSApp.terminate(nil)
    }
}
