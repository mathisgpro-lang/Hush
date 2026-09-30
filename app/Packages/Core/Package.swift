// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Core",
    platforms: [.iOS("26.0"), .macOS("26.0")],
    products: [
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "Storage", targets: ["Storage"]),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift", from: "7.0.0"),
    ],
    targets: [
        .target(name: "Domain"),
        .target(name: "Storage", dependencies: ["Domain", .product(name: "GRDB", package: "GRDB.swift")]),
        .testTarget(name: "DomainTests", dependencies: ["Domain"]),
        .testTarget(name: "StorageTests", dependencies: ["Storage", "Domain"]),
    ]
)
