// swift-tools-version: 5.9
import PackageDescription
import Foundation

let package = Package(
    name: "CapacitorPluginLlamamobile",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "CapacitorPluginLlamamobile",
            targets: ["LlamaMobilePlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "8.0.0")
    ],
    targets: [
        .target(
            name: "LlamaMobilePlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm")
            ],
            path: "ios/Sources/LlamaMobilePlugin",
            linkerSettings: [
                .linkedFramework("llama_mobile", path: "ios/Frameworks/llama_mobile.xcframework"),
                .linkedFramework("Accelerate"),
                .linkedFramework("Metal"),
                .linkedFramework("MetalKit"),
                .linkedFramework("AVFoundation"),
                .linkedLibrary("c++")
            ]
        ),
        .testTarget(
            name: "LlamaMobilePluginTests",
            dependencies: ["LlamaMobilePlugin"],
            path: "ios/Tests/LlamaMobilePluginTests")
    ]
)