import AppKit
import CommonUI
import SwiftUI

/// The last section of every Common Tools app's Settings: the family, and this app's version.
public struct CommonToolsSection: View {
    private let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    private let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? ""

    public init() {}

    public var body: some View {
        Section {
            ForEach(CommonTool.all) { CommonToolRow(tool: $0) }
        } header: {
            Text("Common Tools")
        } footer: {
            HStack {
                Text("\(name) \(version)")
                Spacer()
                Link("oddurs.github.io/common-tools", destination: CommonTool.website)
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
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
