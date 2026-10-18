import Foundation

/// An icon as a folder remembers it: its app, and its label when the app gives one, or else where
/// it comes among that app's icons. Window ids and positions change with every launch; these don't.
public struct ItemKey: Codable, Hashable, Sendable {
    public var bundleID: String
    public var label: String?
    public var index: Int

    public init(bundleID: String, label: String? = nil, index: Int = 0) {
        self.bundleID = bundleID
        self.label = label
        self.index = index
    }

    /// The same icon: the same app, and the same label if both have one, else the same index.
    public func matches(_ other: ItemKey) -> Bool {
        guard bundleID == other.bundleID else { return false }
        if let label, let otherLabel = other.label { return label == otherLabel }
        return index == other.index
    }
}

extension FolderEntry {
    /// The key each entry is remembered by. An app's index counts its icons left to right.
    public static func keys(_ entries: [FolderEntry]) -> [ItemKey] {
        var seen: [String: Int] = [:]
        return entries.map { entry in
            let app = entry.owner.bundleID ?? entry.owner.appName
            let index = seen[app, default: 0]
            seen[app] = index + 1
            let label = [entry.owner.label, entry.owner.title].compactMap { $0 }.first { !$0.isEmpty }
            return ItemKey(bundleID: app, label: label, index: index)
        }
    }
}

/// The folders, in the order they sit in the menu bar from left to right, and which icons each
/// holds. More always exists and holds every icon no other folder claims.
public struct FolderConfig: Codable, Equatable, Sendable {
    public struct Folder: Codable, Equatable, Identifiable, Sendable {
        public var id: String
        public var name: String
        public var symbol: String
        public var members: [ItemKey]

        public init(id: String, name: String, symbol: String, members: [ItemKey] = []) {
            self.id = id
            self.name = name
            self.symbol = symbol
            self.members = members
        }
    }

    public static let moreID = "more"
    public static let more = Folder(id: moreID, name: "More", symbol: "ellipsis.circle")
    /// What the symbol picker offers, and what a new folder starts with.
    public static let symbols = [
        "folder", "tray", "archivebox", "briefcase", "hammer", "wrench.and.screwdriver", "gearshape", "bolt",
        "star", "heart", "bookmark", "tag", "person", "music.note", "camera", "cloud", "lock", "chart.bar",
        "ellipsis.circle",
    ]

    public private(set) var folders: [Folder]

    public init(folders: [Folder] = [FolderConfig.more]) {
        self.folders = folders
        normalize()
    }

    /// Reads what `encoded` wrote; anything unreadable is a fresh start with only More.
    public init(data: Data?) {
        let decoded = data.flatMap { try? JSONDecoder().decode(FolderConfig.self, from: $0) }
        self.init(folders: decoded?.folders ?? [Self.more])
    }

    public var encoded: Data { (try? JSONEncoder().encode(self)) ?? Data() }

    public func folder(_ id: String) -> Folder? { folders.first { $0.id == id } }

    /// The folder an icon belongs in: the first that claims it, or More.
    public func folderID(for key: ItemKey) -> String {
        folders.first { $0.id != Self.moreID && $0.members.contains { $0.matches(key) } }?.id ?? Self.moreID
    }

    /// Each folder's rows, in menu bar order, every entry in exactly one folder.
    public func contents(of entries: [FolderEntry]) -> [String: [FolderEntry]] {
        var result: [String: [FolderEntry]] = [:]
        for (entry, key) in zip(entries, FolderEntry.keys(entries)) {
            result[folderID(for: key), default: []].append(entry)
        }
        return result
    }

    // MARK: Editing

    /// Adds a folder at the left end and returns its id.
    @discardableResult
    public mutating func add(name: String, symbol: String = "folder", id: String = UUID().uuidString) -> String {
        folders.insert(Folder(id: id, name: name, symbol: symbol), at: 0)
        return id
    }

    public mutating func rename(_ id: String, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let i = folders.firstIndex(where: { $0.id == id }) else { return }
        folders[i].name = trimmed
    }

    public mutating func setSymbol(_ id: String, to symbol: String) {
        guard let i = folders.firstIndex(where: { $0.id == id }) else { return }
        folders[i].symbol = symbol
    }

    /// Moves a folder one place left (`by: -1`) or right (`by: 1`), as far as the ends.
    public mutating func move(_ id: String, by offset: Int) {
        guard let i = folders.firstIndex(where: { $0.id == id }) else { return }
        let j = min(max(i + offset, 0), folders.count - 1)
        guard i != j else { return }
        folders.insert(folders.remove(at: i), at: j)
    }

    /// Deletes a folder; its icons go back to More. More itself can't be deleted.
    public mutating func delete(_ id: String) {
        guard id != Self.moreID else { return }
        folders.removeAll { $0.id == id }
    }

    /// Puts an icon in a folder, taking it out of any other.
    public mutating func assign(_ key: ItemKey, to id: String) {
        for i in folders.indices { folders[i].members.removeAll { $0.matches(key) } }
        guard id != Self.moreID, let i = folders.firstIndex(where: { $0.id == id }) else { return }
        folders[i].members.append(key)
    }

    /// More always exists, holds no explicit members, and ids are unique.
    private mutating func normalize() {
        var seen = Set<String>()
        folders = folders.filter { seen.insert($0.id).inserted }
        if let i = folders.firstIndex(where: { $0.id == Self.moreID }) {
            folders[i].members = []
        } else {
            folders.append(Self.more)
        }
    }
}
