import AppKit
import CommonUI
import SwiftUI

/// The last section of every Common Tools app's Settings: the family, its promise, and this app's version.
public struct CommonToolsSection: View {
    private let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    private let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? ""
    /// Only a development build has it (scripts/task build outside CI), so only it shows a commit.
    private let commit = Bundle.main.object(forInfoDictionaryKey: "CommonToolsCommit") as? String

    /// What every app promises, under the family list, in these words.
    public static let promise =
        "Free and open source, forever. Nothing you do is ever reported; nothing leaves your Mac."

    public init() {}

    /// "Common Bar 0.4.0", and in a development build the commit too: "Common Bar 0.4.0 (1a2b3c4-dirty)".
    static func versionLine(name: String, version: String, commit: String?) -> String {
        guard let commit, !commit.isEmpty else { return "\(name) \(version)" }
        let sha = commit.hasSuffix("-dirty") ? String(commit.dropLast(6)) : commit
        return "\(name) \(version) (\(sha.prefix(7))\(sha == commit ? "" : "-dirty"))"
    }

    public var body: some View {
        Section {
            ForEach(CommonTool.all) { CommonToolRow(tool: $0) }
        } header: {
            Text("Common Tools")
        } footer: {
            VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                SettingsFootnote(Self.promise)
                HStack {
                    Text(Self.versionLine(name: name, version: version, commit: commit))
                    Spacer()
                    Link("oddurs.github.io/common-tools", destination: CommonTool.website)
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
    }
}

private struct CommonToolRow: View {
    let tool: CommonTool

    var body: some View {
        LabeledRow(tool.name, subtitle: tool.summary) {
            if let icon = tool.icon {
                Image(nsImage: icon).resizable()
            } else {
                RoundedRectangle(cornerRadius: Tokens.Radius.sm, style: .continuous).fill(.quaternary)
            }
        } trailing: {
            if tool.isThisApp {
                Text("This app").foregroundStyle(.secondary)
            } else if let url = tool.installedURL {
                Button("Open") { NSWorkspace.shared.openApplication(at: url, configuration: .init()) }
            } else {
                Button("Get…") { NSWorkspace.shared.open(tool.page) }
            }
        }
    }
}
