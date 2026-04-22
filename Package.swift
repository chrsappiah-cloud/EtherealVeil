// swift-tools-version: 5.9
// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson

import PackageDescription

let package = Package(
    name: "EtherealVeil",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(name: "EtherealVeil", targets: ["EtherealVeil"])
    ],
    targets: [
        .target(
            name: "EtherealVeil",
            path: "EtherealVeil",
            // EtherealVeilApp.swift uses @main — excluded so SPM doesn't
            // try to find a duplicate entry point when building as a library.
            exclude: ["EtherealVeilApp.swift"]
        ),
        .testTarget(
            name: "EtherealVeilTests",
            dependencies: ["EtherealVeil"],
            path: "Tests/EtherealVeilTests"
        )
    ]
)
