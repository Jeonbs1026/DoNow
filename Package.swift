// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "DoNowFeature",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "DoNowFeature", targets: ["DoNowFeature"])
    ],
    targets: [
        .target(name: "DoNowFeature")
    ]
)
