// swift-tools-version: 5.10
// ─────────────────────────────────────────────────────────────────────────────
// RUNNING TESTS
// Tests require Xcode.app (not just Command Line Tools) because XCTest.framework
// is only shipped with Xcode, not with the standalone xctools package.
//
// From the command line:
//   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
//   swift test
//
// From Xcode:
//   Open HoloBrowser.xcworkspace → Cmd+U
// ─────────────────────────────────────────────────────────────────────────────
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
