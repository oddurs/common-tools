// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CommonColor",
    platforms: [.macOS(.v14)],
    dependencies: [.package(path: "../../packages/CommonKit")],
    targets: [
        .target(name: "ColorKit"),
        .executableTarget(
            name: "CommonColor",
            dependencies: [
                "ColorKit", .product(name: "CommonKit", package: "CommonKit"),
                .product(name: "CommonUI", package: "CommonKit"),
                .product(name: "CommonShortcut", package: "CommonKit"),
            ],
            linkerSettings: [.linkedFramework("ServiceManagement")]
        ),
        .testTarget(name: "ColorKitTests", dependencies: ["ColorKit"]),
        .testTarget(name: "CommonColorTests", dependencies: [.product(name: "CommonTesting", package: "CommonKit")]),
    ]
)
