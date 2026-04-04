# SagaImageReader

An image reader for [Saga](https://github.com/loopwerk/Saga) that turns images into Items with EXIF metadata. Supports JPEG, PNG, WebP, and TIFF.

Uses [Scry](https://github.com/loopwerk/Scry) for cross-platform EXIF parsing — works on both macOS and Linux.

## Installation

```swift
let package = Package(
  name: "MyWebsite",
  dependencies: [
    .package(url: "https://github.com/loopwerk/Saga", from: "3.0.0"),
    .package(url: "https://github.com/loopwerk/SagaImageReader", from: "1.0.0"),
  ],
  targets: [
    .target(
      name: "MyWebsite",
      dependencies: ["Saga", "SagaImageReader"]),
  ]
)
```

## Usage

```swift
import SagaImageReader

try await Saga(input: "content", output: "deploy")
  .register(
    folder: "photos",
    metadata: ImageMetadata.self,
    readers: [.imageReader],
    writers: [
      .itemWriter(swim(renderPhoto)),
    ]
  )
  .run()
```

The `.imageReader` reads image files and extracts EXIF metadata as frontmatter.

## ImageMetadata

SagaImageReader ships with `ImageMetadata`, a ready-made `Metadata` type with all common EXIF fields as optionals — camera info, lens, exposure settings, GPS coordinates, dates, and more.

You can also define your own metadata struct with just the fields you need:

```swift
struct PhotoMetadata: Metadata {
  let make: String?
  let model: String?
  let iso: Int?
}
```
