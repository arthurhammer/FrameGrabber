// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ThumbnailSlider",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "ThumbnailSlider",
            targets: ["ThumbnailSlider"]),
    ],
    targets: [
        .target(
            name: "ThumbnailSlider",
            dependencies: []),
        .testTarget(
            name: "ThumbnailSliderTests",
            dependencies: ["ThumbnailSlider"]),
    ]
)
