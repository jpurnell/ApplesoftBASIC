// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ApplesoftBASIC",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ApplesoftBASICLib",
            targets: ["ApplesoftBASICLib"]
        ),
        .executable(
            name: "applesoft",
            targets: ["ApplesoftBASIC"]
        ),
    ],
    targets: [
        .target(
            name: "ApplesoftBASICLib"
        ),
        .systemLibrary(
            name: "CLineEditor"
        ),
        .executableTarget(
            name: "ApplesoftBASIC",
            dependencies: ["ApplesoftBASICLib", "CLineEditor"]
        ),
        .testTarget(
            name: "ApplesoftBASICTests",
            dependencies: ["ApplesoftBASICLib"]
        ),
    ]
)
