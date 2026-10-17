// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CommonShot",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "ShotKit"),
        .executableTarget(
            name: "CommonShot",
            dependencies: ["ShotKit"],
            linkerSettings: [
                .linkedFramework("Carbon"), .linkedFramework("ScreenCaptureKit"),
                .linkedFramework("ServiceManagement"), .linkedFramework("Vision"),
            ]
        ),
        .testTarget(name: "ShotKitTests", dependencies: ["ShotKit"]),
        .testTarget(name: "CommonShotTests"),
    ]
)
