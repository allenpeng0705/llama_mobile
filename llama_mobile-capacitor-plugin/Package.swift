// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LlamaMobileCapacitorPlugin",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "LlamaMobileCapacitorPlugin",
            targets: ["LlamaMobileCapacitorPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "8.0.0")
    ],
    targets: [
        .binaryTarget(
            name: "llama_mobile",
            path: "ios/Libraries/llama_mobile.xcframework"
        ),
        .target(
            name: "LlamaMobileCapacitorPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm"),
                "llama_mobile"
            ],
            path: "ios/Sources"),
        .testTarget(
            name: "LlamaMobileCapacitorPluginTests",
            dependencies: ["LlamaMobileCapacitorPlugin"],
            path: "ios/Tests")
    ]
)