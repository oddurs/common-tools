import Foundation

/// The recent picks, newest first, at most `limit` of them. Picking a colour that is already
/// there moves it to the front instead of listing it twice, so the two newest are always two
/// different colours to compare.
public struct History: Equatable, Sendable {
    public static let limit = 12

    public private(set) var colors: [ColorValue]

    public init(_ colors: [ColorValue] = []) {
        self.colors = Array(colors.prefix(Self.limit))
    }

    public var current: ColorValue? { colors.first }

    /// The newest two, when there are two.
    public var contrast: Contrast? {
        colors.count >= 2 ? Contrast(colors[0], colors[1]) : nil
    }

    public mutating func add(_ color: ColorValue) {
        colors.removeAll { $0.matches(color) }
        colors.insert(color, at: 0)
        if colors.count > Self.limit { colors.removeLast(colors.count - Self.limit) }
    }

    /// Takes one pick out, and says where it was, so Undo can put it back there.
    @discardableResult
    public mutating func remove(at index: Int) -> ColorValue {
        colors.remove(at: index)
    }

    /// Puts back a pick that `remove(at:)` took out, where it was, unless it has been picked again since.
    public mutating func restore(_ color: ColorValue, at index: Int) {
        guard !colors.contains(where: { $0.matches(color) }) else { return }
        colors.insert(color, at: min(index, colors.count))
        if colors.count > Self.limit { colors.removeLast(colors.count - Self.limit) }
    }

    public mutating func clear() {
        colors.removeAll()
    }

    // MARK: Saving

    /// Each colour as its Display P3 components, the space the picks come from, to six places:
    /// readable in `defaults read`, and finer than any display stores.
    public func encoded() throws -> Data {
        try JSONEncoder().encode(colors.map(Saved.init))
    }

    /// An unreadable history is an error the caller reports; it is never silently emptied.
    public init(decoding data: Data) throws {
        self.init(try JSONDecoder().decode([Saved].self, from: data).map { try $0.color() })
    }

    struct Unreadable: Error {}

    /// What a launch starts with: the history saved under `key`, or an empty one. An unreadable
    /// history is moved aside to `<key>.unreadable` rather than overwritten by the next save, and
    /// the error comes back so the caller can report it.
    public static func load(from defaults: UserDefaults, key: String) -> (History, Error?) {
        guard let data = defaults.data(forKey: key) else { return (History(), nil) }
        do {
            return (try History(decoding: data), nil)
        } catch {
            defaults.set(data, forKey: key + ".unreadable")
            defaults.removeObject(forKey: key)
            return (History(), error)
        }
    }

    public func save(to defaults: UserDefaults, key: String) throws {
        defaults.set(try encoded(), forKey: key)
    }

    private struct Saved: Codable {
        let p3: [Double]

        init(_ color: ColorValue) {
            let c = color.components(in: .displayP3)
            p3 = [c.x, c.y, c.z].map { ($0 * 1_000_000).rounded() / 1_000_000 }
        }

        func color() throws -> ColorValue {
            guard p3.count == 3, p3.allSatisfy(\.isFinite) else { throw Unreadable() }
            return ColorValue(.displayP3, red: p3[0], green: p3[1], blue: p3[2])
        }
    }
}

extension ColorValue {
    /// The same colour, give or take what saving to six places loses.
    func matches(_ other: ColorValue) -> Bool {
        let difference = abs(components(in: .displayP3) - other.components(in: .displayP3))
        return difference.max() < 0.000_005
    }
}

private func abs(_ v: SIMD3<Double>) -> SIMD3<Double> { v.map { Swift.abs($0) } }
