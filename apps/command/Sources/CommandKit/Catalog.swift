import Foundation

/// Everything the panel searches besides files. Joined once when a list changes rather than on every
/// keystroke: nearly a thousand candidates, each copied with its retains, for a list that rarely changes.
public struct Catalog: Sendable {
    public var apps: [Candidate] = [] { didSet { joined = [:] } }
    public var panes: [Candidate] = [] { didSet { joined = [:] } }
    public var commands: [Candidate] = [] { didSet { joined = [:] } }
    public var shortcuts: [Candidate] = [] { didSet { joined = [:] } }
    public var appActions: [Candidate] = [] { didSet { joined = [:] } }

    private var joined: [Int: [Candidate]] = [:]

    public init() {}

    public mutating func candidates(includingPanes: Bool, includingActions: Bool) -> [Candidate] {
        let key = (includingPanes ? 1 : 0) | (includingActions ? 2 : 0)
        if let cached = joined[key] { return cached }
        let all = apps + (includingPanes ? panes : []) + commands + (includingActions ? shortcuts + appActions : [])
        joined[key] = all
        return all
    }
}

/// The apps running now, read once when the panel opens. The action menu asks whether a result's app is
/// running for every row each time the list draws, so this answers from a set instead of asking the
/// system about every running process each time.
public struct RunningApps: Sendable, Equatable {
    /// Quit and Hide for the apps with a Dock icon.
    public var actions: [Actions.RunningApp]
    private var paths: Set<String>

    /// `bundles` is every running app, with a Dock icon or not, since a menu bar app can be quit too.
    public init(actions: [Actions.RunningApp] = [], bundles: [URL] = []) {
        self.actions = actions
        var paths: Set<String> = []
        for url in bundles {
            paths.insert(url.standardizedFileURL.path)
            // /Applications/Safari.app is a symlink to where the system runs it from.
            paths.insert(url.resolvingSymlinksInPath().path)
        }
        self.paths = paths
    }

    /// No file system calls: an app's id already holds its resolved path (`AppCatalog`).
    public func contains(_ item: Item) -> Bool {
        guard item.kind == .application, let url = item.fileURL else { return false }
        if paths.contains(url.standardizedFileURL.path) { return true }
        return item.id.hasPrefix("app:") && paths.contains(String(item.id.dropFirst(4)))
    }
}
