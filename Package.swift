// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ApplesoftBASIC",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "ApplesoftBASICLib",
            targets: ["ApplesoftBASICLib"]
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
            dependencies: [
                "ApplesoftBASICLib",
                .target(name: "CLineEditor", condition: .when(platforms: [.macOS])),
            ]
        ),
        .testTarget(
            name: "ApplesoftBASICTests",
            dependencies: ["ApplesoftBASICLib"]
        ),
    ]
)
