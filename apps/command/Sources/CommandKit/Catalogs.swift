import Foundation

/// Finds installed apps by walking the folders apps live in. No index, no Spotlight query: a few hundred
/// directory entries, read in a few milliseconds, so the list is never stale for long.
public enum AppCatalog {
    public static var standardRoots: [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return [
            "/Applications", "/System/Applications", "/System/Library/CoreServices/Applications",
            home.appending(path: "Applications").path,
        ].map { URL(filePath: $0, directoryHint: .isDirectory) }
    }

    /// Apps that live outside the usual folders but people expect to find.
    public static let extras = [URL(filePath: "/System/Library/CoreServices/Finder.app")]

    /// Folders inside a root are searched this deep, for /Applications/Utilities and suites like
    /// /Applications/Adobe Photoshop/.
    static let depth = 2

    /// Apps win a tie with a System Settings pane or topic: "gc" means Google Chrome before Game Center.
    static let weight = 3

    public static func scan(
        roots: [URL] = standardRoots, extras: [URL] = extras, displayName: (URL) -> String = defaultDisplayName
    ) -> [Candidate] {
        var seen: Set<String> = []
        var candidates: [Candidate] = []
        func add(_ url: URL) {
            let resolved = url.resolvingLinks.resolvingSymlinksInPath().path
            guard seen.insert(resolved).inserted else { return }
            let fileName = url.deletingPathExtension().lastPathComponent
            let name = displayName(url)
            let item = Item(
                id: "app:" + resolved, title: name, subtitle: "", kind: .application,
                action: .open(url))
            candidates.append(Candidate(item, alternatives: [fileName], weight: weight))
        }
        for root in roots { walk(root, depth: depth, found: add) }
        for url in extras where FileManager.default.fileExists(atPath: url.path) { add(url) }
        return candidates
    }

    static func walk(_ folder: URL, depth: Int, found: (URL) -> Void) {
        // Not .skipsHiddenFiles: /Applications/Safari.app is a symlink into a cryptex, flagged hidden.
        let entries =
            (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.isDirectoryKey]))
            ?? []
        for url in entries where !url.lastPathComponent.hasPrefix(".") {
            if url.pathExtension == "app" {
                found(url)
            } else if depth > 0, (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true {
                walk(url, depth: depth - 1, found: found)
            }
        }
    }

    /// The localised name Finder shows, without ".app".
    public static func defaultDisplayName(_ url: URL) -> String {
        let name = FileManager.default.displayName(atPath: url.path)
        return name.hasSuffix(".app") ? String(name.dropLast(4)) : name
    }
}

extension URL {
    /// What a symlink or a Finder alias points to, or the URL itself. /Applications/Safari.app is a symlink
    /// into a cryptex, and some installers leave aliases in ~/Applications.
    var resolvingLinks: URL {
        (try? URL(resolvingAliasFileAt: self, options: [.withoutUI, .withoutMounting])) ?? self
    }
}

/// The panes of System Settings and the topics inside them, read from the extensions that provide them, so
/// the list follows the macOS version instead of a hard-coded table. Topics and their keywords come from the
/// same search-terms files System Settings' own search uses: "dark" finds Appearance, "low power" Battery.
public enum SettingsPanes {
    public static let standardDirectory = URL(filePath: "/System/Library/ExtensionKit/Extensions")

    /// Topics rank below apps and panes with an equally good name; there are hundreds of them.
    static let topicWeight = -12

    struct Topic: Equatable {
        var title: String
        var keywords: [String]
    }

    /// `isPortable` hides topics that only apply to laptops, such as Low Power Mode, or only to desktops.
    public static func scan(directory: URL = standardDirectory, isPortable: Bool) -> [Candidate] {
        let entries =
            (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        var seenNames: Set<String> = []
        return entries.sorted { $0.path < $1.path }.flatMap { url -> [Candidate] in
            guard url.pathExtension == "appex", let bundle = Bundle(url: url), let info = bundle.infoDictionary,
                let identifier = info["CFBundleIdentifier"] as? String,
                let attributes = info["EXAppExtensionAttributes"] as? [String: Any],
                attributes["EXExtensionPointIdentifier"] as? String == "com.apple.Settings.extension.ui",
                let settings = attributes["SettingsExtensionAttributes"] as? [String: Any],
                settings["allowsXAppleSystemPreferencesURLScheme"] as? Bool == true,
                let target = URL(string: "x-apple.systempreferences:" + identifier)
            else { return [] }
            var name = readableName(
                localized: bundle.localizedInfoDictionary?["CFBundleDisplayName"] as? String,
                raw: info["CFBundleDisplayName"] as? String)
            if let shown = name, !seenNames.insert(shown).inserted { name = nil }
            let terms = (settings["searchTermsFileName"] as? String)
                .flatMap { bundle.url(forResource: $0, withExtension: "searchTerms") }
                .flatMap { NSDictionary(contentsOf: $0) as? [String: Any] }
            // Panes drawn from an SF Symbol have a proper icon; the rest show as a generic extension.
            let hasIcon = (info["CFBundleIcons"] as? [String: Any])?["ISGraphicIconConfiguration"] != nil
            return candidates(
                identifier: identifier, name: name, topics: terms.map { topics(in: $0, isPortable: isPortable) } ?? [],
                target: target, icon: hasIcon ? url : nil)
        }
    }

    static func topics(in terms: [String: Any], isPortable: Bool) -> [Topic] {
        terms.keys.sorted().flatMap { section -> [Topic] in
            let strings = (terms[section] as? [String: Any])?["localizableStrings"] as? [[String: Any]] ?? []
            return strings.compactMap { entry in
                guard let title = entry["title"] as? String, !title.isEmpty,
                    !(entry["portableOnly"] as? Bool == true && !isPortable),
                    !(entry["desktopOnly"] as? Bool == true && isPortable)
                else { return nil }
                let keywords = (entry["index"] as? String ?? "").split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                return Topic(title: title, keywords: keywords)
            }
        }
    }

    static func candidates(identifier: String, name: String?, topics: [Topic], target: URL, icon: URL?)
        -> [Candidate]
    {
        let paneKey = name.map(Usage.key)
        var paneKeywords: [String] = []
        var seenTitles: Set<String> = []
        var result: [Candidate] = []
        for topic in topics {
            let key = Usage.key(topic.title)
            // A topic named like its pane is the pane itself; its keywords find the pane.
            if key == paneKey {
                paneKeywords += topic.keywords
                continue
            }
            guard seenTitles.insert(key).inserted else { continue }
            let item = Item(
                id: "pane:\(identifier)#\(topic.title)", title: topic.title,
                subtitle: name ?? "", kind: .settings,
                action: .open(target), iconFile: icon)
            // Hundreds of long topic names would match almost any three letters as initials.
            result.append(Candidate(item, keywords: topic.keywords, weight: topicWeight, matchesWordStarts: true))
        }
        if let name {
            let item = Item(
                id: "pane:" + identifier, title: name, subtitle: "", kind: .settings,
                action: .open(target), iconFile: icon)
            result.insert(Candidate(item, keywords: paneKeywords), at: 0)
        }
        return result
    }

    /// The localised name when there is one. Otherwise the raw name, unless it is an internal one like
    /// "PowerPreferences" or "HeadphoneSettingsExtension" that nobody would recognise.
    static func readableName(localized: String?, raw: String?) -> String? {
        if let localized, !localized.isEmpty { return localized }
        guard let raw, !raw.isEmpty else { return nil }
        let chars = Array(raw)
        let isInternal = zip(chars, chars.dropFirst()).contains { $0.isLowercase && $1.isUppercase }
        return isInternal ? nil : raw
    }
}

/// The Spotlight query for files whose name has a word starting with each word typed.
public enum FileQuery {
    public static func spotlightQuery(for query: String) -> String? {
        let words = query.split(whereSeparator: \.isWhitespace)
        guard !words.isEmpty else { return nil }
        let names = words.map { "kMDItemDisplayName == \"\(escape(String($0)))*\"cdw" }
        // Apps come from AppCatalog, which knows their localised names.
        return (names + ["kMDItemContentType != \"com.apple.application-bundle\""]).joined(separator: " && ")
    }

    static func escape(_ word: String) -> String {
        var escaped = ""
        for c in word {
            if c == "\\" || c == "\"" || c == "*" || c == "'" { escaped.append("\\") }
            escaped.append(c)
        }
        return escaped
    }
}

/// Turns what Spotlight found into results: one per path, without clutter, ranked up when recently used.
public enum FileResults {
    public struct Found: Sendable {
        public var path: String
        public var isFolder: Bool
        public var lastUsed: Date?

        public init(path: String, isFolder: Bool, lastUsed: Date?) {
            self.path = path
            self.isFolder = isFolder
            self.lastUsed = lastUsed
        }
    }

    /// Caches, app internals, dot-folders, and build output match plenty of names and are never what
    /// anyone is looking for.
    static let clutter = ["/Library/", "/.", ".app/", "/node_modules/", "/target/", "/DerivedData/", "/__pycache__/"]

    /// Recently opened files, most recent first, for the Files scope with nothing typed.
    public static func recent(_ found: [Found], home: String, now: Date) -> [Candidate] {
        let ordered = found.filter { $0.lastUsed != nil }.sorted { $0.lastUsed! > $1.lastUsed! }
        return candidates(ordered, home: home, now: now)
    }

    public static func candidates(_ found: [Found], home: String, now: Date) -> [Candidate] {
        // Spotlight can list one file twice, for instance while it re-indexes it.
        var seen: Set<String> = []
        return found.compactMap { file in
            guard !isClutter(file.path), seen.insert(file.path).inserted else { return nil }
            return candidate(file, home: home, now: now)
        }
    }

    static func isClutter(_ path: String) -> Bool {
        clutter.contains { path.contains($0) }
    }

    static func candidate(_ file: Found, home: String, now: Date) -> Candidate {
        let item = item(path: file.path, isFolder: file.isFolder, home: home)
        // Something opened this week is more likely the one you mean than something from years ago, and
        // either beats a file nobody has ever opened, which is usually generated.
        var weight: Int
        if let lastUsed = file.lastUsed {
            let age = now.timeIntervalSince(lastUsed)
            weight = age < 7 * 86400 ? 8 : age < 30 * 86400 ? 4 : 0
        } else {
            weight = -12
        }
        // Of folders with one name, the one nearer the top is usually meant: ~/Projects, not a Projects
        // folder five levels into something else. Mild, so it orders look-alikes without outweighing use.
        if file.isFolder { weight -= depthPenalty(file.path, home: home) }
        return Candidate(item, weight: weight)
    }

    /// 0 for a folder one or two levels below the home folder or the disk, rising by one for every two
    /// levels deeper, to at most 3.
    static func depthPenalty(_ path: String, home: String) -> Int {
        let relative = path == home || path.hasPrefix(home + "/") ? path.dropFirst(home.count) : Substring(path)
        let depth = relative.split(separator: "/").count
        return min(max(depth - 1, 0), 6) / 2
    }

    /// A row for a file or folder, its subtitle the folder it is in, with the home folder as "~".
    static func item(path: String, isFolder: Bool, home: String, title: String? = nil) -> Item {
        let url = URL(filePath: path, directoryHint: isFolder ? .isDirectory : .notDirectory)
        let parent = url.deletingLastPathComponent().path
        let shown = parent == home || parent.hasPrefix(home + "/") ? "~" + parent.dropFirst(home.count) : parent
        return Item(
            id: "file:" + path, title: title ?? url.lastPathComponent, subtitle: shown,
            kind: isFolder ? .folder : .file, action: .open(url))
    }
}

/// The folders people mean when they type a folder's name: /Applications, not ~/Applications or a copy in
/// a backup; ~/Library before /Library. Spotlight can't supply them: the file query covers the home folder
/// only, the index rarely records when a folder was opened, and a name like "Documents" fills the result cap
/// with app containers before it reaches ~/Documents.
public enum Places {
    public struct Place: Sendable, Equatable {
        public var url: URL
        public var weight: Int

        public init(url: URL, weight: Int) {
            self.url = url
            self.weight = weight
        }
    }

    /// Above a look-alike folder opened this week (+8 in `FileResults`), so the main one wins its name. A
    /// choice for the query (+120) or steady use (up to +40) still overrides it.
    static let mainWeight = 10
    /// The system's folders of the same names, below the main ones and below a look-alike used this week.
    static let systemWeight = 6

    /// The well-known folders that exist on this Mac, from the system's own list rather than spelled-out
    /// paths. The first URL of each domain is the real folder; later ones are the cryptex copies macOS
    /// mounts under /System.
    public static func standard(_ fileManager: FileManager = .default) -> [Place] {
        func first(_ directory: FileManager.SearchPathDirectory, _ domain: FileManager.SearchPathDomainMask) -> URL? {
            fileManager.urls(for: directory, in: domain).first
        }
        let userLibrary = first(.libraryDirectory, .userDomainMask)
        let main: [URL?] = [
            first(.applicationDirectory, .localDomainMask),
            first(.adminApplicationDirectory, .systemDomainMask),
            fileManager.homeDirectoryForCurrentUser,
            first(.desktopDirectory, .userDomainMask),
            first(.documentDirectory, .userDomainMask),
            first(.downloadsDirectory, .userDomainMask),
            first(.picturesDirectory, .userDomainMask),
            first(.moviesDirectory, .userDomainMask),
            first(.musicDirectory, .userDomainMask),
            userLibrary,
            // iCloud Drive has no search-path constant; it is this folder of the user's Library.
            userLibrary?.appending(path: "Mobile Documents/com~apple~CloudDocs", directoryHint: .isDirectory),
            first(.sharedPublicDirectory, .userDomainMask),
        ]
        let system: [(URL?, Int)] = [
            (first(.applicationDirectory, .systemDomainMask), systemWeight),
            (first(.adminApplicationDirectory, .localDomainMask), systemWeight),
            (first(.libraryDirectory, .localDomainMask), systemWeight),
            // Below /Library, which shares its name and is the one people open.
            (first(.libraryDirectory, .systemDomainMask), systemWeight - 1),
        ]
        var seen: Set<String> = []
        return (main.map { ($0, mainWeight) } + system).compactMap { url, weight in
            guard let url, fileManager.fileExists(atPath: url.path), seen.insert(url.path).inserted else {
                return nil
            }
            return Place(url: url, weight: weight)
        }
    }

    /// Places as folder results. A place named like an app yields to it: "Music" opens Music, with the
    /// Music folder next.
    public static func candidates(
        _ places: [Place], home: String, yieldingTo apps: [Candidate] = [],
        displayName: (URL) -> String = { FileManager.default.displayName(atPath: $0.path) }
    ) -> [Candidate] {
        let appTitles = Set(apps.map { Usage.key($0.item.title) })
        return places.map { place in
            let path = place.url.path
            let title = displayName(place.url)
            let item = FileResults.item(path: path, isFolder: true, home: home, title: title)
            // The folder's own name finds it when Finder shows a localised one; the home folder is also "Home".
            var alternatives = [place.url.lastPathComponent].filter { !$0.contains("~") }
            if path == home { alternatives.append("Home") }
            let weight = appTitles.contains(Usage.key(title)) ? AppCatalog.weight - 1 : place.weight
            return Candidate(item, alternatives: alternatives, weight: weight)
        }
    }
}
