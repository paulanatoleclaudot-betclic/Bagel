// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Bagel",
    products: [
        .library(name: "Bagel", targets: ["Bagel"])
    ],
    dependencies: [
        .package(url: "https://github.com/daltoniam/Starscream.git", .exact("4.0.4")),
    ],
    targets: [
        .target(
            name: "Bagel",
            dependencies: ["Starscream"],
            path: "iOS/Source"
        )
    ],
    swiftLanguageVersions: [.v5]
)
