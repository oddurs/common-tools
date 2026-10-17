import AppKit

/// For checking changes without pressing the shortcut. Both use their own settings, so they never
/// change yours, and need Screen Recording access for the terminal running them.
///
/// - `CommonShot --capture out.png` runs the whole pipeline on the main display: freeze, size, encode,
///   copy to the clipboard, then write what the clipboard holds to `out.png`.
/// - `CommonShot --overlay out.png [x,y,w,h]` shows the overlay, with that selection dragged if given or
///   the window under the pointer highlighted if not, captures it, and quits.
@MainActor
enum Review {
    enum Request {
        case capture(String)
        case overlay(String, selection: CGRect?)
    }

    static func request(from arguments: [String]) -> Request? {
        if let index = arguments.firstIndex(of: "--capture"), index + 1 < arguments.count {
            return .capture(arguments[index + 1])
        }
        if let index = arguments.firstIndex(of: "--overlay"), index + 1 < arguments.count {
            let numbers = arguments.dropFirst(index + 2).first?.split(separator: ",").compactMap { Double($0) }
            let selection = numbers.flatMap {
                $0.count == 4 ? CGRect(x: $0[0], y: $0[1], width: $0[2], height: $0[3]) : nil
            }
            return .overlay(arguments[index + 1], selection: selection)
        }
        return nil
    }

    static func run(_ request: Request) {
        let preferences = Preferences(defaults: UserDefaults(suiteName: "review")!)
        preferences.showsPreview = false
        preferences.historyLimit = 0
        let controller = AppController(preferences: preferences, interactive: false)
        Task {
            do {
                let freeze = try await Capture.freeze()
                switch request {
                case .capture(let output):
                    let still = freeze.stills[0]
                    try await controller.deliver(still.image, scale: still.scale, screen: nil)
                    guard let png = NSPasteboard.general.data(forType: .png) else { throw OutputError.encoding }
                    try png.write(to: URL(filePath: output))
                    print(
                        "captured \(still.image.width) × \(still.image.height), wrote the clipboard's PNG to \(output)")
                    exit(0)
                case .overlay(let output, let selection):
                    let overlay = Overlay(freeze: freeze)
                    overlay.show()
                    if let selection { overlay.select(selection) }
                    try await Task.sleep(for: .milliseconds(400))
                    let capture = Process()
                    capture.executableURL = URL(filePath: "/usr/sbin/screencapture")
                    capture.arguments = ["-x", "-m", output]
                    try capture.run()
                    capture.waitUntilExit()
                    print("wrote \(output)")
                    exit(capture.terminationStatus)
                }
            } catch {
                print("failed: \(error.localizedDescription)")
                exit(1)
            }
        }
    }
}
