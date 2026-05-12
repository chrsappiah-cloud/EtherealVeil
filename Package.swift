// swift-tools-version: 6.0
// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson

import PackageDescription

let package = Package(
    name: "EtherealVeil",
    platforms: [
        .iOS(.v18),
        .macOS(.v14)
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
            exclude: [
                "Assets.xcassets",
                "EtherealVeilApp.swift",
                "ExportOptions.plist",
                "Resources"
            ]
        ),
        .testTarget(
            name: "EtherealVeilTests",
            dependencies: ["EtherealVeil"],
            path: "Tests/EtherealVeilTests"
        )
    ]
)
