# SagaImageReader

An image reader for [Saga](https://github.com/loopwerk/Saga). Turns images in your content folder into Items, while still copying them to the output folder.

## Usage

Include `SagaImageReader` in your Package.swift as usual:

```swift
let package = Package(
  name: "MyWebsite",
  dependencies: [
    .package(url: "https://github.com/loopwerk/Saga", from: "1.0.0"),
    .package(url: "https://github.com/loopwerk/SagaImageReader", from: "0.5.0"),
  ],
  targets: [
    .target(
      name: "MyWebsite",
      dependencies: ["Saga", "SagaImageReader"]),
  ]
)
```

And then in your website you can `import SagaImageReader` and use `imageReader`.
