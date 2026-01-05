// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "iOSSDKExample",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "iOSSDKExample",
            type: .dynamic,
            targets: ["iOSSDKExample"])
    ],
    dependencies: [
        .package(name: "LlamaMobileSDK", path: "../../llama_mobile-ios-SDK")
    ],
    targets: [
        .target(
            name: "iOSSDKExample",
            dependencies: [.product(name: "LlamaMobileSDK", package: "LlamaMobileSDK")],
            path: "iOSSDKExample",
            resources: [
                .process("Assets.xcassets")
            ])
    ]
)