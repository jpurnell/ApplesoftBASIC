// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ApplesoftBASIC",
    platforms: [
        .macOS(.v15),
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "ApplesoftBASICLib",
            targets: ["ApplesoftBASICLib"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.3"),
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
