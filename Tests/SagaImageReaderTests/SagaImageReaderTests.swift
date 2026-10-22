@testable import SagaImageReader
import XCTest

final class SagaImageReaderTests: XCTestCase {
  func testCaptureDateInFrontmatter() {
    let result = frontmatter(from: [
      "DateTimeOriginal": "2026:01:05 17:11:42",
      "OffsetTimeOriginal": "+01:00",
      "DateTime": "2026:01:06 09:00:00",
    ], dimensions: (150, 200))

    XCTAssertEqual(result["date"], "2026-01-05 17:11:42+01:00")
  }

  func testCaptureDateFallsBackToDateTime() {
    let result = frontmatter(from: [
      "DateTimeOriginal": "0000:00:00 00:00:00",
      "DateTime": "2026:01:06 09:00:00",
      "OffsetTime": "-05:00",
    ], dimensions: (150, 200))

    XCTAssertEqual(result["date"], "2026-01-06 09:00:00-05:00")
  }

  func testDimensionsComeFromImageHeader() {
    let result = frontmatter(from: [
      "ImageWidth": 4032,
      "ImageLength": 3024,
      "PixelXDimension": 4032,
      "PixelYDimension": 3024,
    ], dimensions: (150, 200))

    XCTAssertEqual(result["imageWidth"], "150")
    XCTAssertEqual(result["imageHeight"], "200")
    XCTAssertNil(result["imageLength"])
    XCTAssertNil(result["pixelXDimension"])
    XCTAssertNil(result["pixelYDimension"])
  }

  func testDimensionsWithoutMetadata() {
    let result = frontmatter(from: [:], dimensions: (150, 200))

    XCTAssertEqual(result, ["imageWidth": "150", "imageHeight": "200"])
  }

  func testDimensionsFollowOrientation() {
    let rotated = frontmatter(from: ["Orientation": 6], dimensions: (150, 200))
    XCTAssertEqual(rotated["imageWidth"], "200")
    XCTAssertEqual(rotated["imageHeight"], "150")

    let flipped = frontmatter(from: ["Orientation": 3], dimensions: (150, 200))
    XCTAssertEqual(flipped["imageWidth"], "150")
    XCTAssertEqual(flipped["imageHeight"], "200")
  }

  func testSagaDate() {
    XCTAssertEqual(sagaDate(fromExifDate: "2026:01:05 17:11:42", offset: "+01:00"), "2026-01-05 17:11:42+01:00")
    XCTAssertEqual(sagaDate(fromExifDate: "2026:01:05 17:11:42", offset: nil), "2026-01-05 17:11:42")
    XCTAssertEqual(sagaDate(fromExifDate: "2026:01:05 17:11:42", offset: "   "), "2026-01-05 17:11:42")
    XCTAssertNil(sagaDate(fromExifDate: "0000:00:00 00:00:00", offset: nil))
    XCTAssertNil(sagaDate(fromExifDate: "    :  :     :  :  ", offset: nil))
  }
}
