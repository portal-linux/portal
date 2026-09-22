// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Portal",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "PortalCore", targets: ["PortalCore"]),
        .executable(name: "portal", targets: ["PortalCLI"]),
        .executable(name: "PortalApp", targets: ["PortalApp"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0")
    ],
    targets: [
        .target(
            name: "PortalCore"
        ),
        .executableTarget(
            name: "PortalCLI",
            dependencies: [
                "PortalCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .executableTarget(
            name: "PortalApp",
            dependencies: ["PortalCore"]
        ),
        .testTarget(
            name: "PortalCoreTests",
            dependencies: ["PortalCore"]
        ),
        .testTarget(
            name: "PortalCLITests",
            dependencies: [
                "PortalCLI",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        )
    ]
)
