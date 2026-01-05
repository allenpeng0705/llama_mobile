// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "LlamaMobileSwiftUIExample",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "LlamaMobileSwiftUIExample",
            targets: ["LlamaMobileSwiftUIExample"]
        )
    ],
    dependencies: [
        .package(
            path: "../../llama_mobile-ios-SDK"
        )
    ],
    targets: [
        .target(
            name: "LlamaMobileSwiftUIExample",
            dependencies: [
                .product(name: "LlamaMobileSDK", package: "LlamaMobileSDK")
            ],
            path: "Sources/LlamaMobileSwiftUIExample"
        )
    ]
)
