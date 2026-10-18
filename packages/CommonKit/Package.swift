// swift-tools-version: 6.0
import PackageDescription

// What every Common Tools app shares. Each app depends on it by path, so a change here is built
// and tested with every app in the same pull request.
//
//   CommonKit      the family list and the Common Tools section of Settings
//   CommonUI       the design system: the tokens generated from packages/common-ui/tokens.json, and
//                  the Settings, card, row, and icon primitives the apps draw with
//   CommonShortcut a global keyboard shortcut: the key and its modifiers, registering it with
//                  Carbon (no Accessibility or Input Monitoring needed), and the Settings recorder.
//                  Its own product, since apps that still carry their own KeyCombo import CommonKit.
//   CommonTesting  what every app's tests share: the family contract and benchmark gates. A plain
//                  library, not a test target, so apps link it from theirs; it imports nothing
//                  from Testing itself.
//   DesignRender   draws the CommonUI primitives into the site's design page, light and dark:
//                  `swift run --package-path packages/CommonKit DesignRender`. Not a product, so no
//                  app builds it; it lives here so the kit's lint and tests build it with the rest.
let package = Package(
    name: "CommonKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "CommonKit", targets: ["CommonKit"]),
        .library(name: "CommonUI", targets: ["CommonUI"]),
        .library(name: "CommonShortcut", targets: ["CommonShortcut"]),
        .library(name: "CommonTesting", targets: ["CommonTesting"]),
    ],
    targets: [
        .target(name: "CommonUI"),
        .target(name: "CommonKit", dependencies: ["CommonUI"]),
        .target(name: "CommonShortcut", dependencies: ["CommonUI"], linkerSettings: [.linkedFramework("Carbon")]),
        .target(name: "CommonTesting", dependencies: ["CommonKit"]),
        .executableTarget(name: "DesignRender", dependencies: ["CommonKit", "CommonUI"]),
        .testTarget(name: "CommonKitTests", dependencies: ["CommonKit", "CommonTesting"]),
        .testTarget(name: "CommonUITests", dependencies: ["CommonUI"]),
        .testTarget(name: "CommonShortcutTests", dependencies: ["CommonShortcut"]),
        .testTarget(name: "DesignRenderTests", dependencies: ["DesignRender"]),
    ]
)
