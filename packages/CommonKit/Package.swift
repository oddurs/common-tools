// swift-tools-version: 6.0
import PackageDescription

// What every Common Tools app shares. Each app depends on it by path, so a change here is built
// and tested with every app in the same pull request.
//
//   CommonKit  the family list and the Common Tools section of Settings
//   CommonUI   the design system: the tokens generated from packages/common-ui/tokens.json, and
//              the Settings, card, row, and icon primitives the apps draw with
let package = Package(
    name: "CommonKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "CommonKit", targets: ["CommonKit"]),
        .library(name: "CommonUI", targets: ["CommonUI"]),
    ],
    targets: [
        .target(name: "CommonUI"),
        .target(name: "CommonKit", dependencies: ["CommonUI"]),
        .testTarget(name: "CommonKitTests", dependencies: ["CommonKit"]),
        .testTarget(name: "CommonUITests", dependencies: ["CommonUI"]),
    ]
)
