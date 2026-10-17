// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CommonGlyph",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "GlyphKit"),
        .executableTarget(
            name: "CommonGlyph",
            dependencies: ["GlyphKit"],
            linkerSettings: [.linkedFramework("ServiceManagement"), .linkedFramework("Vision")]
        ),
        .testTarget(name: "GlyphKitTests", dependencies: ["GlyphKit"]),
        .testTarget(name: "CommonGlyphTests"),
    ]
)
