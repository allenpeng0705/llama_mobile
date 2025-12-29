// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LlamaMobileSDK",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "LlamaMobileSDK",
            targets: ["LlamaMobileSDK"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "LlamaMobileSDK",
            dependencies: ["LlamaMobileXCFramework"],
            path: "LlamaMobileSDK",
            cSettings: [
                .headerSearchPath("../Frameworks/llama_mobile.xcframework/ios-arm64/llama_mobile.framework/Headers/"),
                .headerSearchPath("../Frameworks/llama_mobile.xcframework/ios-arm64/llama_mobile.framework/Headers/llama_cpp/")
            ],
            swiftSettings: [
                .define("SWIFT_PACKAGE"),
                .unsafeFlags(["-import-objc-header", "LlamaMobileSDK/LlamaMobileSDK-Bridging-Header.h"])
            ]),






        .binaryTarget(
            name: "LlamaMobileXCFramework",
            path: "./Frameworks/llama_mobile.xcframework"),
        .testTarget(
            name: "LlamaMobileSDKTests",
            dependencies: ["LlamaMobileSDK"]),
    ]
)
