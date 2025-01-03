// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "AppleMenu",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "AppleMenu", targets: ["AppleMenu"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "AppleMenu",
            dependencies: [],
            path: "Sources/AppleMenu"
        )
    ]
) 