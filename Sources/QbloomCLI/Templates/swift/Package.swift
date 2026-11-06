// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "{{TARGET}}",
  products: [.library(name: "QbloomSwiftBackend", type: .dynamic, targets: ["QbloomSwiftBackend"])],
  targets: [
    .target(name: "QbloomSwiftBackend"),
    .testTarget(name: "QbloomSwiftBackendTests", dependencies: ["QbloomSwiftBackend"]),
  ]
)
