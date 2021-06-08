// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "Bagel",
    platforms: [
        .iOS(.v9),
        .macOS(.v10_10),
    ],
    products: [
        .library(name: "Bagel", targets: ["Bagel"])
    ],
    dependencies: [
        .package(url: "https://github.com/paulanatoleclaudot-betclic/CocoaAsyncSocket.git", .revision("9b2cfedabfa421523e5edd9f2409999ba567a427")),
    ],
    targets: [
        .target(
            name: "Bagel",
            dependencies: ["CocoaAsyncSocket"],
            path: "iOS/Source",
			publicHeadersPath: ""
        )
    ]
)
