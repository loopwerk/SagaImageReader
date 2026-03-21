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
    .package(url: "https://github.com/loopwerk/Saga.git", "2.0.3"..<"4.0.0"),
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
