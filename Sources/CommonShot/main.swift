import AppKit

/// Never shown, since the app has no Dock icon, but its key equivalents are how ⌘C, ⌘V, and ⌘A reach
/// the Settings window, and how ⌘W closes it.
@MainActor func makeMainMenu() -> NSMenu {
    let main = NSMenu()
    let app = NSMenu()
    app.addItem(withTitle: "Quit Common Shot", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    main.addItem(withTitle: "Common Shot", action: nil, keyEquivalent: "").submenu = app

    let edit = NSMenu(title: "Edit")
    edit.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
    edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
    edit.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
    edit.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
    main.addItem(withTitle: "Edit", action: nil, keyEquivalent: "").submenu = edit

    let window = NSMenu(title: "Window")
    window.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
    main.addItem(withTitle: "Window", action: nil, keyEquivalent: "").submenu = window
    return main
}

MainActor.assumeIsolated {
    let app = NSApplication.shared
    app.mainMenu = makeMainMenu()
    app.setActivationPolicy(.accessory)
    if let review = Review.request(from: CommandLine.arguments) {
        Review.run(review)
        app.run()
    } else {
        let controller = AppController()
        app.delegate = controller
        withExtendedLifetime(controller) { app.run() }
    }
}
