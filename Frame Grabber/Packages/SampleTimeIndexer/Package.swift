// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SampleTimeIndexer",
    platforms: [.iOS(.v14)],
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
