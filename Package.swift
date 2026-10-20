// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "GlanceCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "GlanceCore", targets: ["GlanceCore"])
    ],
    targets: [
        .target(
            name: "GlanceCore",
            path: "Sources/Core"
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: ["GlanceCore"],
            path: "Tests/CoreTests"
        )
    ]
)
