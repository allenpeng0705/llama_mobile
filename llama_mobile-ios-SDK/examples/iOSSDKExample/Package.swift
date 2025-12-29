// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "LlamaMobileiOSExample",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "LlamaMobileiOSExample", targets: ["LlamaMobileiOSExample"])
    ],
    dependencies: [
        .package(name: "LlamaMobileSDK", path: "../..")
    ],
    targets: [
        .target(
            name: "LlamaMobileiOSExample",
            dependencies: ["LlamaMobileSDK"],
            path: "."
        )
    ]
)