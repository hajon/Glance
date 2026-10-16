// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "GlanceCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "GlanceCore", targets: ["Core"])
    ],
    targets: [
        .target(
            name: "Core",
            path: "Sources/Core"
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core"],
            path: "Tests/CoreTests"
        )
    ]
)
