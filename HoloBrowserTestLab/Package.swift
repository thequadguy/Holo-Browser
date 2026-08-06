// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "HoloBrowserTestLab",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "HoloBrowserTestLab",
            targets: ["HoloBrowserTestLab"]
        )
    ],
    targets: [
        .executableTarget(
            name: "HoloBrowserTestLab",
            path: "Sources/HoloBrowserTestLab"
        )
    ]
)
