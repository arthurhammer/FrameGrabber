// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FrameIndexer",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "FrameIndexer",
            targets: ["FrameIndexer"]),
    ],
    targets: [
        .target(
            name: "FrameIndexer",
            dependencies: []),
        .testTarget(
            name: "FrameIndexerTests",
            dependencies: ["FrameIndexer"]),
    ]
)
