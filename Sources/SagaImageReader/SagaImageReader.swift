import Foundation
import Saga
import Scry

// MARK: - ImageMetadata

/// A ready-made Metadata type for images with the image size and common EXIF, TIFF, and GPS fields.
/// All EXIF properties are optional since not every image contains every field.
public struct ImageMetadata: Metadata {
  // MARK: Dimensions

  /// The displayed size, read from the image header and corrected for the EXIF orientation.
  public let imageWidth: Int
  public let imageHeight: Int

  // MARK: Image info

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
    Reader(supportedExtensions: ["jpg", "jpeg", "png", "webp"], copySourceFiles: true) { absoluteSource in
      let frontmatter = try readImageMetadata(from: absoluteSource.string)
      return (title: absoluteSource.lastComponentWithoutExtension, body: "", frontmatter: frontmatter)
    }
  }
}

// MARK: - Metadata extraction

private func readImageMetadata(from path: String) throws -> [String: String] {
  let dimensions = try Scry.dimensions(fromFileAt: path)
  let properties = (try? Scry.metadata(fromFileAt: path)) ?? [:]
  return frontmatter(from: properties, dimensions: dimensions)
}

/// Converts Scry's metadata and the image size into Saga frontmatter
func frontmatter(from properties: [String: Any], dimensions: (width: Int, height: Int)) -> [String: String] {
  var result: [String: String] = [:]

  for (key, value) in properties where !exifDimensionKeys.contains(key) {
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

  // Orientations 5 to 8 rotate the image by 90°, so the displayed width is the stored height
  let isRotated = (5 ... 8).contains(properties["Orientation"] as? Int ?? 1)
  let (width, height) = isRotated ? (dimensions.height, dimensions.width) : dimensions

  // Saga frontmatter is all strings
  result["imageWidth"] = String(width)
  result["imageHeight"] = String(height)

  return result
}

/// The size as written into the metadata by the exporting app, which can be missing or out of date.
/// The size from the image header is used instead.
private let exifDimensionKeys: Set = ["ImageWidth", "ImageLength", "PixelXDimension", "PixelYDimension"]

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
