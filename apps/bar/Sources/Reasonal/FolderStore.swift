import BarKit
import Foundation
import Observation

/// The folders as the user arranged them, saved in the app's defaults, and the icons last seen
/// left of the divider, for Settings to assign.
@MainActor
@Observable
final class FolderStore {
    static let key = "folders"

    var config: FolderConfig {
        didSet {
            guard config != oldValue else { return }
            UserDefaults.standard.set(config.encoded, forKey: Self.key)
            onChange(oldValue)
        }
    }

    /// Every icon left of the divider, in menu bar order, as the last refresh found them.
    var entries: [FolderEntry] = []

    @ObservationIgnored var onChange: (FolderConfig) -> Void = { _ in }

    init() {
        config = FolderConfig(data: UserDefaults.standard.data(forKey: Self.key))
    }

    /// The key an entry is kept by, among the entries it was found with.
    func key(of entry: FolderEntry) -> ItemKey? {
        guard let i = entries.firstIndex(where: { $0.id == entry.id }) else { return nil }
        return FolderEntry.keys(entries)[i]
    }
}
