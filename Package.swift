// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FileWatcherApp",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(
            name: "FileWatcherApp",
            targets: ["FileWatcherApp"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0")
    ],
    targets: [
        .executableTarget(
            name: "FileWatcherApp",
            dependencies: ["Yams"],
            path: "Sources/FileWatcherApp",
            resources: [.process("Resources")]
        )
    ]
)
