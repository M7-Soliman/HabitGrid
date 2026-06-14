// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HabitCore",
    platforms: [
        .macOS(.v13),
        .iOS(.v17),
    ],
    products: [
        .library(name: "HabitCore", targets: ["HabitCore"]),
    ],
    targets: [
        .target(name: "HabitCore"),
        .testTarget(name: "HabitCoreTests", dependencies: ["HabitCore"]),
    ]
)
