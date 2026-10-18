import AppKit
import CommandKit
import CoreServices
import Foundation
import IOKit.ps
import os

/// Everything that can be searched, and what has been chosen before.
@MainActor
final class Library {
    private var catalog = Catalog()
    var commands: [Candidate] {
        get { catalog.commands }
        set { catalog.commands = newValue }
    }
    /// What runs now, for Quit and Hide and for the action menu. Read when the panel opens.
    private(set) var running = RunningApps()
    /// The well-known folders, searched with files; read with the apps, since a place yields to an app of its name.
    private(set) var places: [Candidate] = []
    private(set) var usage: Usage
    var onChange: (() -> Void)?

    private var scannedAt: Date?
    private var scanning = false
    /// Long enough that opening the panel twice in a row doesn't rescan, short enough that a newly
    /// installed app shows up the next time you look for it.
    private static let staleAfter: TimeInterval = 30

    nonisolated private static let log = Logger(subsystem: "com.oddurs.commoncommand", category: "library")

    private static var usageURL: URL {
        URL.applicationSupportDirectory.appending(path: "Common Command/usage.json")
    }

    init() {
        usage =
            (try? Data(contentsOf: Self.usageURL)).flatMap { try? JSONDecoder().decode(Usage.self, from: $0) }
            ?? Usage()
        // App icons have dark variants, and the drawn ones follow the system's appearance when it changes.
        DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("AppleInterfaceThemeChangedNotification"), object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                IconCache.shared.removeAll()
                Icons.shared.removeAll()
                self?.prerenderIcons()
            }
        }
    }

    func candidates(includingPanes: Bool, includingActions: Bool) -> [Candidate] {
        catalog.candidates(includingPanes: includingPanes, includingActions: includingActions)
    }

    /// Reads the running apps off the main thread when the panel opens: asking each of a hundred processes
    /// for its name and bundle takes 5 ms, more on the first open. The panel shows at once with the list
    /// from last time, which is nearly always the same, and updates only if it changed.
    func refreshRunningApps() async {
        let own = Bundle.main.bundleIdentifier
        let running = await Task.detached(priority: .userInitiated) {
            let apps = NSWorkspace.shared.runningApplications
            return RunningApps(
                actions: apps.compactMap { app in
                    guard app.activationPolicy == .regular, let id = app.bundleIdentifier, id != own,
                        let url = app.bundleURL, let name = app.localizedName
                    else { return nil }
                    return Actions.RunningApp(name: name, bundleIdentifier: id, url: url)
                },
                bundles: apps.compactMap(\.bundleURL))
        }.value
        guard running != self.running else { return }
        self.running = running
        catalog.appActions = Actions.appActions(running.actions)
        onChange?()
    }

    /// Rescans in the background; the current lists keep answering until the new ones arrive.
    func refreshIfStale() {
        guard !scanning, scannedAt.map({ Date().timeIntervalSince($0) > Self.staleAfter }) ?? true else { return }
        scanning = true
        let needsPanes = catalog.panes.isEmpty
        Task {
            let (apps, panes, places) = await Task.detached(priority: .userInitiated) {
                let apps = AppCatalog.scan()
                let places = Places.candidates(
                    Places.standard(), home: FileManager.default.homeDirectoryForCurrentUser.path,
                    yieldingTo: apps)
                return (apps, needsPanes ? SettingsPanes.scan(isPortable: Self.hasBattery) : [], places)
            }.value
            catalog.apps = apps
            self.places = places
            // System Settings changes only with macOS, so its panes are read once per launch.
            if needsPanes { catalog.panes = panes }
            prerenderIcons()
            catalog.shortcuts = await Task.detached(priority: .userInitiated) { Self.listShortcuts() }.value
            scannedAt = Date()
            scanning = false
            onChange?()
        }
    }

    /// Draws the icons of every app and pane in the background, once each, so a row never waits on Icon
    /// Services. Only new apps cost anything after the first scan.
    private func prerenderIcons() {
        let paths = (catalog.apps + catalog.panes).compactMap { $0.item.fileURL?.path ?? $0.item.iconFile?.path }
        Task.detached(priority: .utility) { IconCache.shared.prerender(paths) }
    }

    nonisolated static let shortcutsApp = URL(filePath: "/System/Applications/Shortcuts.app")

    /// The user's shortcuts, from the `shortcuts` tool that ships with macOS. Takes about 50 ms, so it runs
    /// with the app scan. If the tool fails, the list stays empty and the rest of search is unaffected.
    nonisolated static func listShortcuts() -> [Candidate] {
        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/shortcuts")
        process.arguments = ["list"]
        let output = Pipe()
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            log.error("couldn't list shortcuts: \(error.localizedDescription, privacy: .public)")
            return []
        }
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return [] }
        return Actions.shortcuts(
            Actions.shortcutNames(fromList: String(decoding: data, as: UTF8.self)), icon: shortcutsApp)
    }

    /// Whether this Mac runs on a battery, so laptop-only settings such as Low Power Mode are offered only
    /// where they exist.
    nonisolated static var hasBattery: Bool {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
            let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef]
        else { return false }
        return sources.contains { source in
            let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any]
            return description?[kIOPSTypeKey] as? String == kIOPSInternalBatteryType
        }
    }

    func record(_ item: Item, query: String) {
        usage.record(item.id, query: query, at: Date())
        let usage = usage
        let url = Self.usageURL
        Task.detached(priority: .utility) {
            do {
                try FileManager.default.createDirectory(
                    at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                try JSONEncoder().encode(usage).write(to: url, options: .atomic)
            } catch {
                // Losing one launch from the history isn't worth interrupting anyone over.
                Library.log.error("couldn't save usage: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}

/// Files by name, from the Spotlight index. MDQuery rather than NSMetadataQuery because it can cap the
/// result count, so a one-letter query returns in milliseconds instead of gathering every match.
enum FileSearch {
    static let maximumResults = 60

    static func run(_ query: String) -> [Candidate] {
        guard let string = FileQuery.spotlightQuery(for: query) else { return [] }
        return FileResults.candidates(
            found(matching: string), home: FileManager.default.homeDirectoryForCurrentUser.path, now: Date())
    }

    /// Files opened in the last month, most recent first, for the Files scope with nothing typed.
    static func recent() -> [Candidate] {
        let query = "kMDItemLastUsedDate >= $time.today(-30) && kMDItemContentType != \"com.apple.application-bundle\""
        return FileResults.recent(
            found(matching: query), home: FileManager.default.homeDirectoryForCurrentUser.path, now: Date())
    }

    private static func found(matching string: String) -> [FileResults.Found] {
        guard let mdQuery = MDQueryCreate(kCFAllocatorDefault, string as CFString, nil, nil) else { return [] }
        MDQuerySetSearchScope(mdQuery, ["kMDQueryScopeHome"] as CFArray, 0)
        MDQuerySetMaxCount(mdQuery, maximumResults)
        guard MDQueryExecute(mdQuery, CFOptionFlags(kMDQuerySynchronous.rawValue)) else { return [] }
        return (0..<MDQueryGetResultCount(mdQuery)).compactMap { index -> FileResults.Found? in
            guard let raw = MDQueryGetResultAtIndex(mdQuery, index) else { return nil }
            let mdItem = Unmanaged<MDItem>.fromOpaque(raw).takeUnretainedValue()
            guard let path = MDItemCopyAttribute(mdItem, "kMDItemPath" as CFString) as? String else { return nil }
            return FileResults.Found(
                path: path,
                isFolder: MDItemCopyAttribute(mdItem, "kMDItemContentType" as CFString) as? String == "public.folder",
                lastUsed: MDItemCopyAttribute(mdItem, "kMDItemLastUsedDate" as CFString) as? Date)
        }
    }
}
