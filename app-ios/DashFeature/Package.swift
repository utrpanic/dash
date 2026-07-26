// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "DashFeature",
  platforms: [.iOS(.v26)],
  products: [
    .library(
      name: "DashFeature",
      targets: ["DashFeature"]
    ),
  ],
  dependencies: [ .package(path: "../DashPlatform") ],
  targets: [
    .target(
      name: "DashFeature",
      dependencies: [
        .product(name: "DashPlatform", package: "DashPlatform")
      ],
      path: "DashFeature",
      resources: [
        .process("Resources/Colors.xcassets")
      ]
    ),
    .testTarget(
      name: "DashFeatureTests",
      dependencies: [
        "DashFeature"
      ],
      path: "DashFeatureTests"
    ),
  ],
  swiftLanguageModes: [.v6]
)
