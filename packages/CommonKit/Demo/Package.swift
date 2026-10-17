// swift-tools-version: 6.0
import PackageDescription

// A window to look at CommonKit's Welcome in, without building an app:
//
//   cd packages/CommonKit/Demo && swift run welcome-demo                 # opens the window
//   cd packages/CommonKit/Demo && swift run welcome-demo --screenshot out.png
let package = Package(
    name: "WelcomeDemo",
    platforms: [.macOS(.v14)],
    dependencies: [.package(path: "..")],
    targets: [
        .executableTarget(
            name: "welcome-demo", dependencies: [.product(name: "CommonKit", package: "CommonKit")], path: "Sources")
    ]
)
