import Domain
import Foundation
import ImageIO

/// ImageIO で EXIF の撮影日時と GPS を読む。
public struct ImageIOPhotoMetadataReader: PhotoMetadataReading {
    public init() {}

    public func read(from imageData: Data) -> PhotoMetadata {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        else { return PhotoMetadata() }

        let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any]
        let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any]
        return PhotoMetadata(
            takenAt: (exif?[kCGImagePropertyExifDateTimeOriginal] as? String).flatMap(Self.parseDate),
            coordinate: gps.flatMap(Self.parseCoordinate)
        )
    }

    /// EXIF の日時("2026:10:03 14:05:09")。時刻帯は書かれていないので、端末の時刻帯として読む。
    static func parseDate(_ text: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return formatter.date(from: text)
    }

    static func parseCoordinate(_ gps: [CFString: Any]) -> Coordinate? {
        guard let lat = gps[kCGImagePropertyGPSLatitude] as? Double,
              let lon = gps[kCGImagePropertyGPSLongitude] as? Double else { return nil }
        let latSign = (gps[kCGImagePropertyGPSLatitudeRef] as? String) == "S" ? -1.0 : 1.0
        let lonSign = (gps[kCGImagePropertyGPSLongitudeRef] as? String) == "W" ? -1.0 : 1.0
        return Coordinate(latitude: lat * latSign, longitude: lon * lonSign)
    }
}
