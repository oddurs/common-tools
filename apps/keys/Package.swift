// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CommonKeys",
    platforms: [.macOS("14.4")],
    products: [
        .library(name: "KeysKit", targets: ["KeysKit"]),
        .executable(name: "common-keys", targets: ["KeysCLI"]),
        .executable(name: "CommonKeys", targets: ["CommonKeys"]),
    ],
    dependencies: [.package(path: "../../packages/CommonKit")],
    targets: [
        .target(name: "KeysKit"),
        .executableTarget(
            name: "CommonKeys",
            dependencies: [
                "KeysKit", .product(name: "CommonKit", package: "CommonKit"),
                .product(name: "CommonUI", package: "CommonKit"),
            ]),
        .executableTarget(name: "KeysCLI", dependencies: ["KeysKit"]),
        .testTarget(name: "KeysKitTests", dependencies: ["KeysKit"]),
        .testTarget(
            name: "CommonKeysTests",
            dependencies: ["CommonKeys", .product(name: "CommonTesting", package: "CommonKit")]),
    ]
)
