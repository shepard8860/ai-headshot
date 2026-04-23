// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AIHeadshot",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "AIHeadshot",
            targets: ["AIHeadshot"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AIHeadshot",
            dependencies: [],
            path: "Sources/AIHeadshot",
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "AIHeadshotTests",
            dependencies: ["AIHeadshot"],
            path: "Tests/AIHeadshotTests"
        )
    ]
)
