@testable import DataLayer
import Domain
import Foundation
import ImageIO
import Testing

struct ImageIOPhotoMetadataReaderTests {
    @Test func parsesSouthWestCoordinates() {
        let gps: [CFString: Any] = [
            kCGImagePropertyGPSLatitude: 33.5, kCGImagePropertyGPSLatitudeRef: "S",
            kCGImagePropertyGPSLongitude: 70.6, kCGImagePropertyGPSLongitudeRef: "W",
        ]
        #expect(ImageIOPhotoMetadataReader.parseCoordinate(gps) == Coordinate(latitude: -33.5, longitude: -70.6))
    }

    @Test func parsesExifDate() {
        #expect(ImageIOPhotoMetadataReader.parseDate("2026:10:03 14:05:09") != nil)
        #expect(ImageIOPhotoMetadataReader.parseDate("invalid") == nil)
    }

    @Test func dataWithoutMetadataGivesNothing() {
        let metadata = ImageIOPhotoMetadataReader().read(from: Data([0, 1, 2]))
        #expect(metadata == PhotoMetadata())
    }
}
