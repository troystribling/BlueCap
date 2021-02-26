// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "BlueCap",
    platforms: [ .iOS(.v9) ],
    products: [
        .library(
            name: "BlueCap",
            targets: ["BlueCap"]),
    ],    
    targets: [
        .target(
            name: "BlueCap",
            path: "BlueCapKit"
        ),
        .testTarget(name: "BlueCapTests",
                    dependencies: ["BlueCap"],
                    path: "Tests/BlueCapKitTests"
        ),
    ],
    swiftLanguageVersions: [.v4_2]
)
