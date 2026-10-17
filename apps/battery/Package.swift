// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CommonBattery",
    platforms: [.macOS(.v14)],
    dependencies: [.package(path: "../../packages/CommonKit")],
    targets: [
        .target(name: "BatteryKit", linkerSettings: [.linkedFramework("IOKit")]),
        .executableTarget(
            name: "CommonBattery",
            dependencies: ["BatteryKit", .product(name: "CommonKit", package: "CommonKit")],
            linkerSettings: [
                .linkedFramework("ServiceManagement"), .linkedFramework("UserNotifications"),
            ]
        ),
        .testTarget(name: "BatteryKitTests", dependencies: ["BatteryKit"]),
    ]
)
