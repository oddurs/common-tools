import CommonKit
import Foundation

/// The contract every app in the family keeps, checked from its source tree by one test in each
/// app: the names and identifiers in `apps.json`, `CommonTool.all` and `Resources/Info.plist`
/// agree, and what `scripts/task build` copies into the bundle exists. A changed bundle identifier
/// starts with empty settings, no login item and no permission grants, so a rename ships with a
/// `LegacyIdentity` migration in the app.
public struct AppContract {
    public let slug: String
    /// The repository root: the nearest directory above `file` that holds `apps.json`.
    public let repository: URL

    public struct Failure: Error, CustomStringConvertible {
        public let description: String
    }

    /// `file` is any file under `apps/<slug>/`, by default the test that makes the contract.
    public init(slug: String, file: StaticString = #filePath) throws {
        var directory = URL(fileURLWithPath: "\(file)").deletingLastPathComponent()
        while !FileManager.default.fileExists(atPath: directory.appending(path: "apps.json").path) {
            guard directory.path != "/" else { throw Failure(description: "no apps.json above \(file)") }
            directory = directory.deletingLastPathComponent()
        }
        self.slug = slug
        self.repository = directory
    }

    var app: URL { repository.appending(path: "apps/\(slug)") }

    /// Every way the app departs from the contract, empty when it keeps it. One list rather than
    /// one expectation per rule, so a failing test says everything at once.
    public func violations() throws -> [String] {
        let apps = try dictionary(json: repository.appending(path: "apps.json"))
        guard let entry = apps[slug] as? [String: Any] else { return ["apps.json has no entry for \(slug)"] }
        guard let tool = CommonTool.all.first(where: { $0.id == slug }) else {
            return ["CommonTool.all has no \(slug)"]
        }
        let info = try dictionary(plist: app.appending(path: "Resources/Info.plist"))
        var found: [String] = []
        func same(_ what: String, _ actual: Any?, _ expected: Any?) {
            let actual = actual.map { "\($0)" } ?? "nothing"
            let expected = expected.map { "\($0)" } ?? "nothing"
            if actual != expected { found.append("\(what) is \(actual), not \(expected)") }
        }
        func exists(_ path: String, in base: URL? = nil) {
            if !FileManager.default.fileExists(atPath: (base ?? app).appending(path: path).path) {
                found.append("missing \(path)")
            }
        }

        // One name and one identity, wherever they're written down.
        same("CommonTool.name", tool.name, entry["NAME"])
        same("CommonTool.bundleIdentifier", tool.bundleIdentifier, entry["BUNDLE"])
        same("CFBundleName", info["CFBundleName"], entry["NAME"])
        same("CFBundleDisplayName", info["CFBundleDisplayName"], entry["NAME"])
        same("CFBundleIdentifier", info["CFBundleIdentifier"], entry["BUNDLE"])
        same("CFBundleExecutable", info["CFBundleExecutable"], entry["TARGET"])
        same("LSMinimumSystemVersion", info["LSMinimumSystemVersion"], entry["MIN_MACOS"])
        // The Common naming. A rename keeps to it and ships with a LegacyIdentity migration in the app.
        same("BUNDLE", entry["BUNDLE"], "com.oddurs.common\(slug)")
        same("TARGET", entry["TARGET"], (entry["NAME"] as? String ?? "").replacingOccurrences(of: " ", with: ""))
        same("REPO", entry["REPO"], "common-\(slug)")
        same("DIR", entry["DIR"], "common-\(slug)")
        // Menu bar apps: no Dock icon, no app switcher entry.
        same("LSUIElement", info["LSUIElement"] as? Bool, true)
        let version = info["CFBundleShortVersionString"] as? String ?? ""
        if version.range(of: #"^\d+\.\d+\.\d+$"#, options: .regularExpression) == nil {
            found.append("CFBundleShortVersionString '\(version)' is not major.minor.patch")
        }

        // What the build assembles, and what scripts/release folds.
        exists("Resources/\(info["CFBundleIconFile"] as? String ?? "AppIcon").icns")
        exists("Sources/\(entry["TARGET"] ?? "")")
        exists("Sources/\(entry["KIT"] ?? "")")
        if let changelog = try? String(contentsOf: app.appending(path: "CHANGELOG.md"), encoding: .utf8) {
            if !changelog.contains("\n## [Unreleased]") { found.append("CHANGELOG.md has no [Unreleased] section") }
        } else {
            found.append("missing CHANGELOG.md")
        }
        // The Common Tools section of every app's Settings shows every app's icon from the bundle.
        for tool in CommonTool.all {
            exists("shared/CommonTools/\(tool.id).png", in: repository)
        }
        found += try designViolations(target: entry["TARGET"] as? String ?? "")
        return found
    }

    /// Common UI governs the app target's views. Settings is built from the family's primitives,
    /// and no view picks a colour by hand; in Settings, no view sets a text size or draws a shadow
    /// either, since the system text styles and the tokens decide those. Panels and menus keep
    /// their own metrics, and the library target (status-item renderers, image processing) is
    /// not a view at all, so neither is held to the Settings rules.
    private func designViolations(target: String) throws -> [String] {
        let sources = app.appending(path: "Sources/\(target)")
        guard let files = FileManager.default.enumerator(at: sources, includingPropertiesForKeys: nil) else {
            return []
        }
        var found: [String] = []
        var everything = ""
        for case let file as URL in files where file.pathExtension == "swift" {
            // Code only: a comment that names a primitive, or explains why one isn't used, is not use.
            let text = try String(contentsOf: file, encoding: .utf8).split(
                separator: "\n", omittingEmptySubsequences: false
            )
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")
            everything += text
            let name = file.lastPathComponent
            for literal in [
                "Color(red:", "NSColor(red:", "NSColor(srgbRed:", "NSColor(calibratedRed:", "#colorLiteral",
                "Color(hex:",
            ]
            where text.contains(literal) {
                found.append("\(name) picks a colour by hand (\(literal)); use a token or a system colour")
            }
            if name.contains("Settings") {
                for styling in [".system(size:", ".shadow("] where text.contains(styling) {
                    found.append("\(name) uses \(styling); Settings takes its text styles and depth from Common UI")
                }
            }
        }
        for primitive in ["SettingsWindowHost(", ".settingsForm()", "OpenAtLoginToggle(", "CommonToolsSection()"]
        where !everything.contains(primitive) {
            found.append("Sources/\(target) does not use \(primitive) from Common UI for its Settings")
        }
        return found
    }

    private func dictionary(json url: URL) throws -> [String: Any] {
        guard let object = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any] else {
            throw Failure(description: "\(url.lastPathComponent) is not a JSON object")
        }
        return object
    }

    private func dictionary(plist url: URL) throws -> [String: Any] {
        let data = try Data(contentsOf: url)
        guard let object = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else { throw Failure(description: "\(url.lastPathComponent) is not a property list dictionary") }
        return object
    }
}
