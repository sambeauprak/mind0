// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Mind0",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Mind0",
            path: "Sources/Mind0",
            resources: [.copy("Resources")]
        )
    ]
)
