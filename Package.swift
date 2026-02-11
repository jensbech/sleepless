// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Sleepless",
    platforms: [.macOS(.v13)],
    targets: [
        .target(
            name: "SleeplessKit",
            path: "Sources/SleeplessKit"
        ),
        .executableTarget(
            name: "Sleepless",
            dependencies: ["SleeplessKit"],
            path: "Sources/Sleepless",
            linkerSettings: [.linkedFramework("Cocoa")]
        ),
        .testTarget(
            name: "SleeplessKitTests",
            dependencies: ["SleeplessKit"],
            path: "Tests/SleeplessKitTests"
        ),
    ]
)
