import BarKit
import CommonKit
import CommonUI
import SwiftUI

/// Laid out by the Common Tools Settings standard: the app's own sections, then General, then
/// `CommonToolsSection`, so the apps' Settings windows read the same.
struct SettingsView: View {
    @AppStorage(MenuBarController.showsFolderNamesKey) private var showsFolderNames = true
    @AppStorage(MenuBarController.opensBesideFolderKey) private var opensBesideFolder = true
    @State private var loginProblem: LoginItem.Problem?
    @Bindable var store: FolderStore
    let updates: UpdateCheck

    var body: some View {
        Form {
            Section {
                ForEach(store.config.folders) { folder in
                    FolderRow(folder: folder, store: store)
                }
                Button("Add Folder") { store.config.add(name: "Folder") }
                Toggle("Show folder names in the menu bar", isOn: $showsFolderNames)
            } header: {
                Text("Folders")
            } footer: {
                SettingsFootnote(
                    "Folders sit in the menu bar in this order, left to right. More holds every icon no other folder does."
                )
            }

            Section {
                if store.entries.isEmpty {
                    LabeledContent("Icons", value: "None found yet")
                }
                ForEach(store.entries) { entry in
                    IconRow(entry: entry, store: store)
                }
            } header: {
                Text("Icons in Folders")
            } footer: {
                SettingsFootnote("Every icon left of your folders, and the folder it's in.")
            }

            Section {
                Toggle("Open icons beside their folder", isOn: $opensBesideFolder)
                // Read each second: the switch is flipped in System Settings, not here.
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    let permission = MenuBarController.accessibility
                    LabeledContent(permission.name) {
                        if permission.isGranted {
                            Text("Allowed")
                        } else {
                            Button("Open System Settings…") { NSWorkspace.shared.open(permission.settingsURL) }
                        }
                    }
                }
            } header: {
                Text("Opening Icons")
            } footer: {
                SettingsFootnote(
                    "An icon you choose in a folder opens its menu under that folder: near the divider it is ⌘-dragged in beside the folder and put back afterwards; further along, a copy of its menu opens instead. Off, it opens where it comes on screen. Common Bar needs Accessibility \(MenuBarController.accessibility.reason); it asks the first time you open a folder."
                )
            }

            Section {
                OpenAtLoginToggle(problem: $loginProblem)
                UpdateCheckToggle(updates: updates)
            } header: {
                Text("General")
            } footer: {
                VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                    OpenAtLoginFootnote(loginProblem)
                    UpdateCheckFootnote(updates: updates)
                }
            }

            CommonToolsSection()
        }
        .settingsForm()
    }
}

/// One folder: its symbol, its name, moving it left or right, and deleting it.
private struct FolderRow: View {
    let folder: FolderConfig.Folder
    @Bindable var store: FolderStore
    @State private var name = ""

    var body: some View {
        HStack(spacing: Tokens.Space.sm) {
            Picker("Symbol", selection: symbol) {
                ForEach(FolderConfig.symbols, id: \.self) { symbol in
                    Image(systemName: symbol).tag(symbol)
                }
            }
            .labelsHidden()
            .fixedSize()
            TextField("Name", text: $name)
                .onSubmit { store.config.rename(folder.id, to: name) }
                .onChange(of: name) { _, new in store.config.rename(folder.id, to: new) }
            Button("Move Left", systemImage: "chevron.left") { store.config.move(folder.id, by: -1) }
                .disabled(store.config.folders.first?.id == folder.id)
            Button("Move Right", systemImage: "chevron.right") { store.config.move(folder.id, by: 1) }
                .disabled(store.config.folders.last?.id == folder.id)
            Button("Delete", systemImage: "trash", role: .destructive) { store.config.delete(folder.id) }
                .disabled(folder.id == FolderConfig.moreID)
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
        .onAppear { name = folder.name }
    }

    private var symbol: Binding<String> {
        Binding(get: { folder.symbol }, set: { store.config.setSymbol(folder.id, to: $0) })
    }
}

/// One icon, its app's icon and name, and the folder it's in.
private struct IconRow: View {
    let entry: FolderEntry
    @Bindable var store: FolderStore

    var body: some View {
        Picker(selection: folder) {
            ForEach(store.config.folders) { folder in
                Text(folder.name).tag(folder.id)
            }
        } label: {
            Label {
                Text(entry.name)
            } icon: {
                if let icon = NSRunningApplication(processIdentifier: entry.owner.pid)?.icon {
                    Image(nsImage: icon).resizable().frame(width: Tokens.Space.md, height: Tokens.Space.md)
                }
            }
        }
    }

    private var folder: Binding<String> {
        Binding(
            get: { store.key(of: entry).map(store.config.folderID(for:)) ?? FolderConfig.moreID },
            set: { id in if let key = store.key(of: entry) { store.config.assign(key, to: id) } })
    }
}
