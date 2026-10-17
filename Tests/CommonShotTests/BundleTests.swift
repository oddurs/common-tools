import Foundation
import Testing

/// What scripts/task assembles into the app bundle, checked against the source tree.
@Suite struct BundleTests {
    static let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        .deletingLastPathComponent().deletingLastPathComponent()

    static func infoPlist() throws -> [String: Any] {
        let data = try Data(contentsOf: root.appendingPathComponent("Resources/Info.plist"))
        return try #require(PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any])
    }

    @Test func namesTheApp() throws {
        let info = try Self.infoPlist()
        #expect(info["CFBundleName"] as? String == "Common Shot")
        #expect(info["CFBundleDisplayName"] as? String == "Common Shot")
    }

    @Test func keepsTheIdentifiersSavedSettingsDependOn() throws {
        let info = try Self.infoPlist()
        // Screen Recording access, UserDefaults, the status item position, and the login item live under this id.
        #expect(info["CFBundleIdentifier"] as? String == "com.oddurs.commonshot")
        // scripts/task copies the SwiftPM product of this name into the bundle.
        #expect(info["CFBundleExecutable"] as? String == "CommonShot")
        let target = Self.root.appendingPathComponent("Sources/CommonShot")
        #expect(FileManager.default.fileExists(atPath: target.path))
    }

    @Test func staysAMenuBarOnlyApp() throws {
        let info = try Self.infoPlist()
        #expect(info["LSUIElement"] as? Bool == true)
        #expect(info["LSMinimumSystemVersion"] as? String == "14.0")
    }

    @Test func shipsItsIcon() throws {
        let info = try Self.infoPlist()
        let name = try #require(info["CFBundleIconFile"] as? String)
        let icon = Self.root.appendingPathComponent("Resources/\(name).icns")
        #expect(FileManager.default.fileExists(atPath: icon.path))
    }

    @Test func shipsEveryCommonToolsIcon() {
        // CommonTools.swift loads these by id; scripts/task copies the folder into the bundle.
        for id in ["stats", "keys", "bar", "glyph", "command", "shot"] {
            let icon = Self.root.appendingPathComponent("Resources/CommonTools/\(id).png")
            #expect(FileManager.default.fileExists(atPath: icon.path), "missing \(id).png")
        }
    }
}
