@testable import SagaImageReader
import XCTest

final class SagaImageReaderTests: XCTestCase {
  func testCaptureDateInFrontmatter() {
    let result = frontmatter(from: [
      "DateTimeOriginal": "2026:01:05 17:11:42",
      "OffsetTimeOriginal": "+01:00",
      "DateTime": "2026:01:06 09:00:00",
    ])

    XCTAssertEqual(result?["date"], "2026-01-05 17:11:42+01:00")
  }

  func testCaptureDateFallsBackToDateTime() {
    let result = frontmatter(from: [
      "DateTimeOriginal": "0000:00:00 00:00:00",
      "DateTime": "2026:01:06 09:00:00",
      "OffsetTime": "-05:00",
    ])

    XCTAssertEqual(result?["date"], "2026-01-06 09:00:00-05:00")
  }

  func testSagaDate() {
    XCTAssertEqual(sagaDate(fromExifDate: "2026:01:05 17:11:42", offset: "+01:00"), "2026-01-05 17:11:42+01:00")
    XCTAssertEqual(sagaDate(fromExifDate: "2026:01:05 17:11:42", offset: nil), "2026-01-05 17:11:42")
    XCTAssertEqual(sagaDate(fromExifDate: "2026:01:05 17:11:42", offset: "   "), "2026-01-05 17:11:42")
    XCTAssertNil(sagaDate(fromExifDate: "0000:00:00 00:00:00", offset: nil))
    XCTAssertNil(sagaDate(fromExifDate: "    :  :     :  :  ", offset: nil))
  }
}
