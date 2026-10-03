import CoreLocation
import Foundation
import ImageIO

/// 写真データに入っている、使えるメタデータ(撮影日時・GPS)。無いものは nil。
struct PhotoMetadata {
    var takenAt: Date?
    var coordinate: CLLocationCoordinate2D?
}

enum PhotoMetadataReader {
    static func read(from data: Data) -> PhotoMetadata {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        else { return PhotoMetadata() }

        let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any]
        let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any]
        return PhotoMetadata(
            takenAt: (exif?[kCGImagePropertyExifDateTimeOriginal] as? String).flatMap(parseDate),
            coordinate: gps.flatMap(parseCoordinate)
        )
    }

    /// EXIF の日時("2026:10:03 14:05:09")。時刻帯は書かれていないので、端末の時刻帯として読む。
    static func parseDate(_ text: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return formatter.date(from: text)
    }

    static func parseCoordinate(_ gps: [CFString: Any]) -> CLLocationCoordinate2D? {
        guard let lat = gps[kCGImagePropertyGPSLatitude] as? Double,
              let lon = gps[kCGImagePropertyGPSLongitude] as? Double else { return nil }
        let latSign = (gps[kCGImagePropertyGPSLatitudeRef] as? String) == "S" ? -1.0 : 1.0
        let lonSign = (gps[kCGImagePropertyGPSLongitudeRef] as? String) == "W" ? -1.0 : 1.0
        return CLLocationCoordinate2D(latitude: lat * latSign, longitude: lon * lonSign)
    }
}
