// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "DashPlatform",
  platforms: [.iOS(.v26)],
  products: [
    .library(
      name: "DashPlatform",
      targets: [
        "DashExternalDependencies",
        "DashPlatform",
      ]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", exact: "1.26.0"),
  ],
  targets: [
    .target(
      name: "DashExternalDependencies",
      dependencies: [
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ],
      path: "DashExternalDependencies"
    ),
    .target(
      name: "DashPlatform",
      path: "DashPlatform"
    ),
    .testTarget(
      name: "DashPlatformTests",
      dependencies: [
        "DashPlatform"
      ],
      path: "DashPlatformTests"
    ),
  ],
  swiftLanguageModes: [.v6]
)
