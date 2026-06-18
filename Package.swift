// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacJournal",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MacJournal", targets: ["MacJournal"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "MacJournal",
            path: "Sources/MacJournal"
        )
    ]
)
