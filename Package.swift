// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LMKPI",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "LMKPI", targets: ["LMKPI"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "LMKPI",
            path: "Sources/LMKPI"
        )
    ]
)
