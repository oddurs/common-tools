import ColorKit
import Foundation

/// The recent picks as the panel sees them, saved as they change, so a pick removed from the panel
/// is gone from the next launch too.
@MainActor @Observable
final class Picks {
    private(set) var history: History
    @ObservationIgnored private let save: @MainActor (History) -> Void

    init(_ history: History, save: @escaping @MainActor (History) -> Void = { _ in }) {
        self.history = history
        self.save = save
    }

    func add(_ color: ColorValue) { change { $0.add(color) } }
    func remove(at index: Int) -> ColorValue? {
        guard history.colors.indices.contains(index) else { return nil }
        var removed: ColorValue?
        change { removed = $0.remove(at: index) }
        return removed
    }
    func restore(_ color: ColorValue, at index: Int) { change { $0.restore(color, at: index) } }
    func clear() { change { $0.clear() } }

    private func change(_ edit: (inout History) -> Void) {
        edit(&history)
        save(history)
    }
}
