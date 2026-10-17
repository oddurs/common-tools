import Foundation
import Observation

/// Looks for a newer release of this app, at most once a day, and only once the user has turned it
/// on in Settings. The check is a single unauthenticated GET of the monorepo's release list, the same
/// page anyone can open in a browser: no identifier, no cookie, nothing about this Mac. The app
/// decides what to show; `available` says there is a newer version and where it is.
@MainActor @Observable
public final class UpdateCheck {
    public struct Update: Equatable, Sendable {
        public let version: Version
        /// The release page, with the notes.
        public let page: URL
        /// The app's zip, when the release has one.
        public let download: URL?
    }

    public typealias Fetch = @Sendable (URLRequest) async throws -> Data

    nonisolated public static let releases = URL(
        string: "https://api.github.com/repos/oddurs/common-tools/releases?per_page=100")!
    nonisolated static let interval: TimeInterval = 24 * 60 * 60

    public let tool: CommonTool
    /// A newer version than the one running, once a check has found one.
    public private(set) var available: Update?
    /// Why the last check failed, for Settings to show; nil after a check that worked.
    public private(set) var lastError: String?

    private let current: Version?
    private let defaults: UserDefaults
    private let fetch: Fetch
    private let now: @Sendable () -> Date
    private var loop: Task<Void, Never>?

    /// - Parameters:
    ///   - tool: this app, from `CommonTool.all`.
    ///   - current: the running version; Info.plist's by default.
    ///   - fetch: how to GET; URLSession without cache or cookies by default. Tests pass a stub.
    public init(
        tool: CommonTool, current: Version? = .current, defaults: UserDefaults = .standard,
        now: @escaping @Sendable () -> Date = Date.init, fetch: Fetch? = nil
    ) {
        self.tool = tool
        self.current = current
        self.defaults = defaults
        self.now = now
        self.fetch = fetch ?? Self.plainGET
    }

    /// Off until the user turns it on in Settings. Call `checkIfDue()` after turning it on, so the
    /// first check doesn't wait for the next launch.
    public var isEnabled: Bool {
        get { defaults.bool(forKey: Keys.enabled) }
        set { defaults.set(newValue, forKey: Keys.enabled) }
    }

    public var lastChecked: Date? {
        get { defaults.object(forKey: Keys.lastChecked) as? Date }
        set { defaults.set(newValue, forKey: Keys.lastChecked) }
    }

    /// True when enabled and no check has run in the last day.
    public var isDue: Bool {
        guard isEnabled else { return false }
        guard let last = lastChecked else { return true }
        return now().timeIntervalSince(last) >= Self.interval
    }

    /// Checks now if a check is due; otherwise does nothing. Safe to call at every launch.
    public func checkIfDue() async {
        guard isDue else { return }
        do {
            try await check()
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Checks when due, then again every hour while the app runs, so a Mac that stays up for weeks
    /// still hears about a release within a day. Call once, at launch.
    public func start() {
        loop?.cancel()
        loop = Task { [weak self] in
            while !Task.isCancelled {
                await self?.checkIfDue()
                try? await Task.sleep(for: .seconds(60 * 60))
            }
        }
    }

    /// Checks now, whatever the schedule says, and records the time. Throws when GitHub can't be
    /// read or answers something unexpected.
    public func check() async throws {
        var request = URLRequest(url: Self.releases, timeoutInterval: 15)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        // One fixed string for every app and every Mac, since GitHub refuses requests without one.
        request.setValue("common-tools", forHTTPHeaderField: "User-Agent")
        let data = try await fetch(request)
        let newest = try Self.newest(in: data, for: tool)
        lastChecked = now()
        lastError = nil
        if let newest, let current, newest.version > current {
            available = newest
        } else {
            available = nil
        }
    }

    /// The newest release of `tool` in GitHub's release list, by version rather than by position,
    /// leaving out drafts and prereleases. Nil when the app has no release yet.
    public static func newest(in data: Data, for tool: CommonTool) throws -> Update? {
        let releases = try JSONDecoder().decode([GitHubRelease].self, from: data)
        let asset = "\(tool.name.replacingOccurrences(of: " ", with: "")).zip"
        return
            releases
            .filter { !$0.draft && !$0.prerelease && $0.tagName.hasPrefix("\(tool.id)-v") }
            .compactMap { release -> Update? in
                guard let version = Version(release.tagName) else { return nil }
                let download = release.assets.first { $0.name == asset }?.browserDownloadURL
                return Update(version: version, page: release.htmlURL, download: download)
            }
            .max { $0.version < $1.version }
    }

    private enum Keys {
        static let enabled = "CommonKit.updateCheck.enabled"
        static let lastChecked = "CommonKit.updateCheck.lastChecked"
    }

    private static let plainGET: Fetch = { request in
        let session = URLSession(configuration: .ephemeral)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard http.statusCode == 200 else {
            throw URLError(
                .badServerResponse, userInfo: [NSLocalizedDescriptionKey: "GitHub answered \(http.statusCode)"])
        }
        return data
    }
}

private struct GitHubRelease: Decodable {
    struct Asset: Decodable {
        let name: String
        let browserDownloadURL: URL
        enum CodingKeys: String, CodingKey {
            case name
            case browserDownloadURL = "browser_download_url"
        }
    }
    let tagName: String
    let htmlURL: URL
    let draft: Bool
    let prerelease: Bool
    let assets: [Asset]
    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
        case draft, prerelease, assets
    }
}

extension CommonTool {
    /// The app this code is running in, by bundle identifier; nil in a bare executable such as the demo.
    public static var thisApp: CommonTool? { all.first(where: \.isThisApp) }
}
