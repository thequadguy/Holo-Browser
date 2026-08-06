// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "HoloBrowser",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "HoloBrowser",
            targets: ["HoloBrowser"]
        )
    ],
    targets: [
        .executableTarget(
            name: "HoloBrowser",
            path: "Sources",
            exclude: ["App/HoloBrowser.entitlements", "App/Info.plist", "App/Assets.xcassets"]
        ),
        .testTarget(
            name: "HoloBrowserTests",
            dependencies: ["HoloBrowser"],
            path: "Tests/HoloBrowserTests"
        )
    ]
)
