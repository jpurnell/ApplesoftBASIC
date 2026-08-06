// swift-tools-version: 6.2
// legibility:description: A faithful Applesoft BASIC interpreter written in modern Swift, celebrating Apple's 50th birthday.
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
        // Seeded generation for tests. The interpreter's RND() takes an injected
        // generator precisely so a failing draw reproduces from its seed.
        .package(url: "https://github.com/jpurnell/SwiftDeterminism.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "ApplesoftBASICLib",
            exclude: ["ApplesoftBASICLib.docc"]
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
            dependencies: [
                "ApplesoftBASICLib",
                .product(name: "SwiftDeterminism", package: "SwiftDeterminism"),
            ]
        ),
    ]
)
