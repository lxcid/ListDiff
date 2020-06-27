// swift-tools-version:5.0

import PackageDescription

let pkg = Package(name: "ListDiff")
pkg.platforms = [
   .macOS(.v10_10), .iOS(.v8), .tvOS(.v9), .watchOS(.v2)
]
pkg.products = [
    .library(name: "ListDiff", targets: ["ListDiff"]),
]

let ldf: Target = .target(name: "ListDiff")
ldf.path = "Sources"
pkg.swiftLanguageVersions = [.v4, .v4_2, .v5]
pkg.targets = [
    ldf,
    .testTarget(name: "ListDiffStressTests", dependencies: ["ListDiff"], path: "Tests/ListDiffTests"),
]
