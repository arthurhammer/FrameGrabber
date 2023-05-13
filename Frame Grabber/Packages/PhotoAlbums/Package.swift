// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PhotoAlbums",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "PhotoAlbums",
            targets: ["PhotoAlbums"]),
    ],
    targets: [
        .target(
            name: "PhotoAlbums",
            dependencies: []),
        .testTarget(
            name: "PhotoAlbumsTests",
            dependencies: ["PhotoAlbums"]),
    ]
)
