// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SampleTimeIndexer",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "SampleTimeIndexer",
            targets: ["SampleTimeIndexer"]),
    ],
    targets: [
        .target(
            name: "SampleTimeIndexer",
            dependencies: []),
        .testTarget(
            name: "SampleTimeIndexerTests",
            dependencies: ["SampleTimeIndexer"]),
    ]
)
