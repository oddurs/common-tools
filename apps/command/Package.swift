// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CommonCommand",
    platforms: [.macOS(.v14)],
    dependencies: [.package(path: "../../packages/CommonKit")],
    targets: [
        .target(name: "CommandKit"),
        .executableTarget(
            name: "CommonCommand",
            dependencies: ["CommandKit", .product(name: "CommonKit", package: "CommonKit")],
            linkerSettings: [
                .linkedFramework("Carbon"), .linkedFramework("IOKit"), .linkedFramework("ServiceManagement"),
            ]
        ),
        .testTarget(
            name: "CommandKitTests",
            dependencies: ["CommandKit", .product(name: "CommonTesting", package: "CommonKit")]),
        .testTarget(name: "CommonCommandTests", dependencies: [.product(name: "CommonTesting", package: "CommonKit")]),
    ]
)
