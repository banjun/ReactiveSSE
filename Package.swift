// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ReactiveSSE",
    products: [
        .library(
            name: "ReactiveSSE",
            targets: ["ReactiveSSE"])],
    dependencies: [
        .package(url: "https://github.com/ReactiveCocoa/ReactiveSwift", .upToNextMajor(from: "6.0.0")),
        .package(url: "https://github.com/kareman/FootlessParser", .upToNextMajor(from: "0.4.1"))],
    targets: [
        .target(
            name: "ReactiveSSE",
            dependencies: ["FootlessParser", "ReactiveSwift"],
            path: "ReactiveSSE")])
