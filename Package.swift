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
    .package(url: "https://github.com/loopwerk/Saga.git", "3.8.0" ..< "4.0.0"),
    .package(url: "https://github.com/loopwerk/Scry.git", from: "1.3.0"),
  ],
  targets: [
    .target(
      name: "SagaImageReader",
      dependencies: [
        "Saga",
        "Scry",
      ]
    ),
    .testTarget(
      name: "SagaImageReaderTests",
      dependencies: ["SagaImageReader"]
    ),
  ]
)
