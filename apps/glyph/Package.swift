// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CommonGlyph",
    platforms: [.macOS(.v14)],
    dependencies: [.package(path: "../../packages/CommonKit")],
    targets: [
        .target(name: "GlyphKit"),
        .executableTarget(
            name: "CommonGlyph",
            dependencies: ["GlyphKit", .product(name: "CommonKit", package: "CommonKit")],
            linkerSettings: [.linkedFramework("ServiceManagement"), .linkedFramework("Vision")]
        ),
        .testTarget(name: "GlyphKitTests", dependencies: ["GlyphKit"]),
        .testTarget(name: "CommonGlyphTests", dependencies: [.product(name: "CommonTesting", package: "CommonKit")]),
    ]
)
