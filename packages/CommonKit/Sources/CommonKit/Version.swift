import Foundation

/// A release version, major.minor.patch, as Info.plist, apps.json, and the release tags write it.
public struct Version: Comparable, Hashable, Sendable, CustomStringConvertible {
    public let major: Int
    public let minor: Int
    public let patch: Int

    public init(_ major: Int, _ minor: Int, _ patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    /// Reads "0.4.0", "v0.4.0", or a release tag like "bar-v0.4.0"; nil for anything else. Missing
    /// minor or patch parts read as zero, so "1.2" is 1.2.0.
    public init?(_ text: String) {
        let digits = text.lastIndex(of: "v").map { text[text.index(after: $0)...] } ?? Substring(text)
        let parts = digits.split(separator: ".", omittingEmptySubsequences: false)
        guard (1...3).contains(parts.count) else { return nil }
        let numbers = parts.compactMap { part -> Int? in
            guard !part.isEmpty, part.allSatisfy(\.isNumber) else { return nil }
            return Int(part)
        }
        guard numbers.count == parts.count else { return nil }
        self.init(numbers[0], numbers.count > 1 ? numbers[1] : 0, numbers.count > 2 ? numbers[2] : 0)
    }

    /// This app's version, from its Info.plist.
    public static var current: Version? {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String).flatMap(Version.init)
    }

    public static func < (lhs: Version, rhs: Version) -> Bool {
        (lhs.major, lhs.minor, lhs.patch) < (rhs.major, rhs.minor, rhs.patch)
    }

    public var description: String { "\(major).\(minor).\(patch)" }
}
