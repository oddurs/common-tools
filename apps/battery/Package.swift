// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CommonBattery",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "BatteryKit", linkerSettings: [.linkedFramework("IOKit")]),
        .executableTarget(
            name: "CommonBattery",
            dependencies: ["BatteryKit"],
            linkerSettings: [
                .linkedFramework("ServiceManagement"), .linkedFramework("UserNotifications"),
            ]
        ),
        .testTarget(name: "BatteryKitTests", dependencies: ["BatteryKit"]),
    ]
)
