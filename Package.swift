// swift-tools-version:5.10

import PackageDescription

let package = Package(
  name: "SagaImageReader",
  platforms: [
    .macOS(.v14),
  ],
  products: [
    .library(
      name: "SagaImageReader",
      targets: ["SagaImageReader"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/loopwerk/Saga.git", from: "2.0.3"),
  ],
  targets: [
    .target(
      name: "SagaImageReader",
      dependencies: [
        "Saga",
      ]
    ),
  ]
)
