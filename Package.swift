// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "HardwarePulseCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "HardwarePulseCore", targets: ["Core"])
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
