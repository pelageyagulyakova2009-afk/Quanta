// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Quanta",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Quanta",
            path: "Sources/Quanta",
            resources: [.copy("Resources/PeriodicTableJSON.json")]
        )
    ]
)
