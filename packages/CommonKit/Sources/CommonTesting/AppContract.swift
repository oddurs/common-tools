import CommonKit
import Foundation

/// The contract every app in the family keeps, checked from its source tree by one test in each
/// app: the names and identifiers in `apps.json`, `CommonTool.all` and `Resources/Info.plist`
/// agree, and what `scripts/task build` copies into the bundle exists. Identifiers are forever. An
/// existing install keeps its settings, status item positions, login item and permission grants
/// only while the bundle identifier and executable name stay what they were.
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
