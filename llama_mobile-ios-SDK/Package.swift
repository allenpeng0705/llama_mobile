// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LlamaMobile",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "LlamaMobile",
            targets: ["LlamaMobile"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .binaryTarget(
            name: "llama_mobile",
            path: "llama_mobile.xcframework"
        ),
        // Main Swift wrapper target
        .target(
            name: "LlamaMobile",
            dependencies: ["llama_mobile"],
            path: "Sources/LlamaMobile",
            resources: [.copy("grammars")],
            linkerSettings: [
                .linkedFramework("Foundation"),
                .linkedLibrary("c++"),
            ]
        ),
        // Test target for the Swift wrapper
        .testTarget(
            name: "LlamaMobileTests",
            dependencies: ["LlamaMobile"],
            path: "Tests/LlamaMobileTests"
        )
    ]
)
