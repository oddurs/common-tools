import AppKit
import CommonUI

/// What an app was called before it took the family's naming: its bundle identifier, the names its
/// status items saved their positions under, and its folder in Application Support. A new bundle
/// identifier starts with empty defaults, no login item and no permission grants; `migrate(from:)`
/// carries over what can be carried, once. Permission grants can't be: macOS keys them by bundle
/// identifier, so the app has to ask for them again, and Welcome or the app's own prompt does.
public struct LegacyIdentity: Sendable {
    public struct Folder: Sendable, Equatable {
        public let old: String
        public let new: String

        public init(old: String, new: String) {
            self.old = old
            self.new = new
        }
    }

    public let bundleIdentifier: String
    /// Old autosave name to new. The `NSStatusItem … <name>` keys macOS keeps the position and
    /// visibility under are renamed with it, so the icon stays where the user put it.
    public let statusItems: [String: String]
    /// Keys about the old identity's own permission grants, such as "already asked for
    /// Accessibility". The new identity has no grant, so they would only send the user to a pane the
    /// app isn't listed in yet.
    public let droppedKeys: Set<String>
    /// The app's folder under Application Support, moved when the new one doesn't exist yet.
    public let supportFolder: Folder?

    public init(
        bundleIdentifier: String, statusItems: [String: String] = [:], droppedKeys: Set<String> = [],
        supportFolder: Folder? = nil
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.statusItems = statusItems
        self.droppedKeys = droppedKeys
        self.supportFolder = supportFolder
    }

    /// What one migration did.
    public struct Outcome: Equatable, Sendable {
        /// A copy under the old identity was running and was asked to quit.
        public var quitOldCopy = false
        /// Keys copied from the old defaults; zero when there was nothing to copy, or it was done before.
        public var copiedKeys = 0
        public var movedFolder = false
    }

    /// Carries the old identity's state over to this one. Call it first in `main.swift`, before
    /// anything reads the defaults or makes a status item, and call `followLoginItem()` from
    /// `applicationDidFinishLaunching`. Safe at every launch: each step does nothing once done.
    ///
    /// The old defaults and their plist are left in place, so going back to the old version finds
    /// them; the Application Support folder is moved, since there is only one of it to keep up to date.
    @MainActor @discardableResult
    public static func migrate(from legacy: LegacyIdentity) -> Outcome {
        var outcome = Outcome()
        outcome.quitOldCopy = quitRunningCopy(of: legacy.bundleIdentifier)
        if let domain = Bundle.main.bundleIdentifier, domain != legacy.bundleIdentifier {
            outcome.copiedKeys = legacy.copyDefaults(into: .standard, domain: domain)
        }
        do {
            outcome.movedFolder = try legacy.moveSupportFolder(in: .applicationSupportDirectory)
        } catch {
            // The app runs on without it; the old folder and everything in it stay where they were.
            NSLog("Common Tools: couldn't move \(legacy.supportFolder?.old ?? ""): \(error.localizedDescription)")
        }
        if outcome != Outcome() {
            NSLog(
                "Common Tools: moved over from \(legacy.bundleIdentifier): \(outcome.copiedKeys) settings, "
                    + "folder \(outcome.movedFolder ? "moved" : "unchanged"), old copy "
                    + "\(outcome.quitOldCopy ? "quit" : "not running")")
        }
        return outcome
    }

    /// Copies the old identity's defaults into `defaults`, whose persistent domain is `domain`, when
    /// that domain holds nothing yet. Status item keys are renamed and `droppedKeys` left out. Returns
    /// how many keys it wrote.
    ///
    /// The old domain is read with `persistentDomain(forName:)`, which is the old plist in
    /// ~/Library/Preferences exactly (the apps aren't sandboxed). A suite's
    /// `dictionaryRepresentation()` also holds every global default, which would pin the language and
    /// appearance of the moment into the app's own settings.
    func copyDefaults(into defaults: UserDefaults, domain: String) -> Int {
        guard defaults.persistentDomain(forName: domain)?.isEmpty ?? true,
            let old = defaults.persistentDomain(forName: bundleIdentifier), !old.isEmpty
        else { return 0 }
        let carried = carried(old)
        for (key, value) in carried { defaults.set(value, forKey: key) }
        defaults.set(true, forKey: LoginItemFollow.key)
        return carried.count
    }

    /// The old defaults as the new identity keeps them.
    func carried(_ old: [String: Any]) -> [String: Any] {
        var new: [String: Any] = [:]
        for (key, value) in old where !droppedKeys.contains(key) {
            new[renamed(key)] = value
        }
        return new
    }

    func renamed(_ key: String) -> String {
        guard key.hasPrefix("NSStatusItem ") else { return key }
        for (old, new) in statusItems where key.hasSuffix(" \(old)") {
            return String(key.dropLast(old.count)) + new
        }
        return key
    }

    /// Moves `supportFolder.old` to `supportFolder.new` under `base` when the old one exists and the
    /// new one doesn't. Returns whether it moved. Throws when the move fails, which leaves the old
    /// folder where it was.
    func moveSupportFolder(in base: URL, fileManager: FileManager = .default) throws -> Bool {
        guard let supportFolder else { return false }
        let old = base.appending(path: supportFolder.old, directoryHint: .isDirectory)
        let new = base.appending(path: supportFolder.new, directoryHint: .isDirectory)
        guard fileManager.fileExists(atPath: old.path), !fileManager.fileExists(atPath: new.path) else { return false }
        try fileManager.moveItem(at: old, to: new)
        return true
    }

    /// Asks a copy still running under the old identity to quit, and waits up to two seconds for it,
    /// so it has saved its settings before they are copied. An update replaces the app on disk while
    /// the old process runs on; left alone, both would draw in the menu bar.
    @MainActor
    static func quitRunningCopy(of bundleIdentifier: String) -> Bool {
        let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)
        guard !running.isEmpty else { return false }
        for app in running { app.terminate() }
        let deadline = Date(timeIntervalSinceNow: 2)
        while running.contains(where: { !$0.isTerminated }), Date() < deadline {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))
        }
        return true
    }

    /// Registers this app to open at login when the old one was. No public API reads another bundle
    /// identifier's login item, but the old one stays registered in System Settings › Login Items and
    /// still opens the app at the same path. So once a migration has run, the first launch that comes
    /// from a login item while this identity isn't registered is that old entry, and this identity
    /// takes its place. Call it from `applicationDidFinishLaunching`, while the launch event is current.
    @MainActor
    public static func followLoginItem(defaults: UserDefaults = .standard) {
        let decision = LoginItemFollow.decide(
            pending: defaults.bool(forKey: LoginItemFollow.key), launchedAtLogin: launchedAtLogin,
            registered: LoginItem.isEnabled || LoginItem.problem != nil)
        switch decision {
        case .nothing, .wait:
            return
        case .done:
            defaults.removeObject(forKey: LoginItemFollow.key)
        case .register:
            do {
                try LoginItem.setEnabled(true)
                defaults.removeObject(forKey: LoginItemFollow.key)
            } catch {
                // Left pending, so the next launch at login tries again.
                NSLog("Common Tools: couldn't take over the login item: \(error.localizedDescription)")
            }
        }
    }

    /// Whether this launch came from a login item, as the open-application event says.
    @MainActor
    static var launchedAtLogin: Bool {
        guard let event = NSAppleEventManager.shared().currentAppleEvent,
            event.eventID == AEEventID(kAEOpenApplication)
        else { return false }
        return event.paramDescriptor(forKeyword: AEKeyword(keyAEPropData))?.enumCodeValue
            == OSType(keyAELaunchedAsLogInItem)
    }
}

/// When the app takes over the old identity's login item.
enum LoginItemFollow: Equatable {
    /// No migration is waiting on the login item.
    case nothing
    /// Not yet known whether the old app opened at login.
    case wait
    /// This identity is registered already; nothing is left to follow.
    case done
    /// The old entry opened this app at login: register this identity in its place.
    case register

    static let key = "CommonKit.legacy.followLoginItem"

    static func decide(pending: Bool, launchedAtLogin: Bool, registered: Bool) -> LoginItemFollow {
        guard pending else { return .nothing }
        if registered { return .done }
        return launchedAtLogin ? .register : .wait
    }
}
