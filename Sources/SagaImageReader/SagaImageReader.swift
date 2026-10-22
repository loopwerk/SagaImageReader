import Foundation
import Saga
import Scry

// MARK: - ImageMetadata

/// A ready-made Metadata type for images with common EXIF, TIFF, and GPS fields.
/// All properties are optional since not every image contains every field.
public struct ImageMetadata: Metadata {
  // MARK: Image info

  public let imageWidth: Int?
  public let imageLength: Int?
  public let orientation: Int?
  public let make: String?
  public let model: String?
  public let software: String?
  public let hostComputer: String?
  public let artist: String?
  public let copyright: String?

  // MARK: Lens

  public let lensMake: String?
  public let lensModel: String?

  // MARK: Exposure

  public let exposureTime: String?
  public let fNumber: String?
  public let iso: Int?
  public let apertureValue: String?
  public let brightnessValue: String?
  public let exposureBiasValue: String?
  public let shutterSpeedValue: String?
  public let exposureMode: Int?
  public let exposureProgram: Int?
  public let focalLength: String?
  public let focalLenIn35mmFilm: Int?
  public let flash: Int?
  public let whiteBalance: Int?
  public let meteringMode: Int?
  public let sceneCaptureType: Int?

  // MARK: Dimensions

  public let pixelXDimension: Int?
  public let pixelYDimension: Int?

  // MARK: Dates

  public let dateTimeOriginal: String?
  public let dateTimeDigitized: String?
  public let dateTime: String?

  // MARK: GPS

  public let gpsLatitude: String?
  public let gpsLatitudeRef: String?
  public let gpsLongitude: String?
  public let gpsLongitudeRef: String?
  public let gpsAltitude: String?
  public let gpsAltitudeRef: Int?
  public let gpsSpeed: String?
  public let gpsImgDirection: String?
  public let gpsDateStamp: String?
}

// MARK: - Reader

public extension Reader {
  static var imageReader: Self {
    Reader(supportedExtensions: ["jpg", "jpeg", "png", "webp", "tiff", "tif"], copySourceFiles: true) { absoluteSource in
      let frontmatter = readImageMetadata(from: absoluteSource.string)
      return (title: absoluteSource.lastComponentWithoutExtension, body: "", frontmatter: frontmatter)
    }
  }
}

// MARK: - Metadata extraction

private func readImageMetadata(from path: String) -> [String: String]? {
  guard let properties = try? Scry.metadata(fromFileAt: path) else {
    return nil
  }

  return frontmatter(from: properties)
}

/// Converts Scry's metadata into Saga frontmatter
func frontmatter(from properties: [String: Any]) -> [String: String]? {
  var result: [String: String] = [:]

  for (key, value) in properties {
    let frontmatterKey = lowercasedFirst(key)
    let renamedKey = keyRenames[frontmatterKey] ?? frontmatterKey

    switch value {
    case let array as [Double]:
      // GPS coordinates: convert [degrees, minutes, seconds] to decimal
      let decimal = array.count == 3
        ? array[0] + array[1] / 60.0 + array[2] / 3600.0
        : array[0]
      result[renamedKey] = "\(decimal)"
    case let array as [Any]:
      let elements = array.map { "\($0)" }
      result[renamedKey] = elements.joined(separator: ", ")
    default:
      result[renamedKey] = "\(value)"
    }
  }

  // Use the capture date as Saga's item date, including the time and (if known) the time zone
  for (dateKey, offsetKey) in dateKeys {
    if let exifDate = result[dateKey], let date = sagaDate(fromExifDate: exifDate, offset: result[offsetKey]) {
      result["date"] = date
      break
    }
  }

  return result.isEmpty ? nil : result
}

/// EXIF dates in order of preference, with their matching time zone offsets
private let dateKeys = [
  ("dateTimeOriginal", "offsetTimeOriginal"),
  ("dateTimeDigitized", "offsetTimeDigitized"),
  ("dateTime", "offsetTime"),
]

/// Converts "2026:01:05 17:11:42" with offset "+01:00" → "2026-01-05 17:11:42+01:00".
/// Returns nil for unset dates like "0000:00:00 00:00:00" or blanks, which Saga would fail to parse.
func sagaDate(fromExifDate exifDate: String, offset: String?) -> String? {
  guard exifDate.range(of: #"^\d{4}:\d{2}:\d{2} \d{2}:\d{2}:\d{2}$"#, options: .regularExpression) != nil,
        !exifDate.hasPrefix("0000")
  else {
    return nil
  }

  let parts = exifDate.split(separator: " ")
  let date = parts[0].replacingOccurrences(of: ":", with: "-") + " " + parts[1]

  if let offset, offset.range(of: #"^[+-]\d{2}:\d{2}$"#, options: .regularExpression) != nil {
    return date + offset
  }

  return date
}

private let keyRenames = [
  "isoSpeedRatings": "iso",
]

/// Converts "ISOSpeedRatings" → "isoSpeedRatings", "GPSLatitude" → "gpsLatitude", "Make" → "make"
private func lowercasedFirst(_ string: String) -> String {
  var leadingUpperCount = 0
  for char in string {
    if char.isUppercase {
      leadingUpperCount += 1
    } else {
      break
    }
  }

  if leadingUpperCount <= 1 {
    return string.prefix(1).lowercased() + string.dropFirst()
  }

  // All uppercase (e.g. "GPS" → "gps")
  if leadingUpperCount == string.count {
    return string.lowercased()
  }

  // "ISOSpeedRatings" → lowercase "ISO" but keep the "S" in "Speed" uppercase
  // So we lowercase all but the last uppercase char (which starts the next word)
  let lowercaseCount = leadingUpperCount - 1
  return string.prefix(lowercaseCount).lowercased() + string.dropFirst(lowercaseCount)
}
