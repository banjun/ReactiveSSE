// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ExampleCLI",
    dependencies: [
        .package(url: "../", .branch("master"))],
    targets: [
        .target(
            name: "ExampleCLI",
            dependencies: ["ReactiveSSE"])])
