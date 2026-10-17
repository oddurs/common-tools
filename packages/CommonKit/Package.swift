// swift-tools-version: 6.0
import PackageDescription

// What every Common Tools app shares. Each app depends on it by path, so a change here is built
// and tested with every app in the same pull request.
let package = Package(
    name: "CommonKit",
    platforms: [.macOS(.v14)],
    products: [.library(name: "CommonKit", targets: ["CommonKit"])],
    targets: [
        .target(name: "CommonKit"),
        .testTarget(name: "CommonKitTests", dependencies: ["CommonKit"]),
    ]
)
