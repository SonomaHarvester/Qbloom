// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "qbloom",
    products: [.executable(name: "qbloom", targets: ["QbloomCLI"])],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", exact: "1.8.2")
    ],
    targets: [
        .executableTarget(
            name: "QbloomCLI",
            dependencies: [.product(name: "ArgumentParser", package: "swift-argument-parser")],
            resources: [.copy("Templates")]
        ),
        .testTarget(name: "QbloomCLITests", dependencies: ["QbloomCLI"]),
    ]
)
