// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "LlamaMobile",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "LlamaMobile",
            targets: ["LlamaMobile"]
        ),
    ],
    dependencies: [],
    targets: [
        .binaryTarget(
            name: "llama_mobile",
            path: "./llama_mobile.xcframework"
        ),
        .target(
            name: "LlamaMobile",
            dependencies: ["llama_mobile"],
            path: "Sources/LlamaMobile",
            linkerSettings: [
                .linkedFramework("Accelerate")
            ]
        ),
        .testTarget(
            name: "LlamaMobileTests",
            dependencies: ["LlamaMobile"],
            linkerSettings: [
                .linkedFramework("Accelerate")
            ]
        )
    ]
)
