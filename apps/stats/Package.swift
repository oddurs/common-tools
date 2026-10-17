// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CommonStats",
    platforms: [.macOS(.v14)],
    dependencies: [.package(path: "../../packages/CommonKit")],
    targets: [
        .target(
            name: "StatKit",
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("SystemConfiguration"),
            ]
        ),
        .executableTarget(
            name: "StatBar",
            dependencies: [
                "StatKit",
                .product(name: "CommonKit", package: "CommonKit"),
                .product(name: "CommonUI", package: "CommonKit"),
            ]
        ),
        .testTarget(
            name: "StatKitTests",
            dependencies: ["StatKit", .product(name: "CommonTesting", package: "CommonKit")]),
        .testTarget(name: "CommonStatsTests", dependencies: [.product(name: "CommonTesting", package: "CommonKit")]),
    ]
)
