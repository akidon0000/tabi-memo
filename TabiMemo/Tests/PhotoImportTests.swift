import CoreLocation
import Foundation
import ImageIO
import Testing
@testable import TabiMemo

struct PhotoImportTests {
    private func point(_ minutes: Double, _ lat: Double, _ lon: Double) -> PhotoLocationGuess.Point {
        .init(date: Date(timeIntervalSince1970: minutes * 60), coordinate: .init(latitude: lat, longitude: lon))
    }

    @Test func guessIsMidpointOfNeighbors() {
        let center = PhotoLocationGuess.center(
            for: Date(timeIntervalSince1970: 30 * 60),
            among: [point(0, 35.0, 139.0), point(60, 36.0, 140.0)]
        )
        #expect(center?.latitude == 35.5)
        #expect(center?.longitude == 139.5)
    }

    @Test func guessUsesOneSideWhenOnlyOneExists() {
        let late = PhotoLocationGuess.center(for: Date(timeIntervalSince1970: 120 * 60), among: [point(0, 35.0, 139.0)])
        #expect(late?.latitude == 35.0)
        let early = PhotoLocationGuess.center(for: Date(timeIntervalSince1970: -60), among: [point(0, 36.0, 140.0)])
        #expect(early?.longitude == 140.0)
    }

    @Test func guessIsNilWithoutPoints() {
        #expect(PhotoLocationGuess.center(for: .now, among: []) == nil)
    }

    @Test func parsesSouthWestCoordinates() {
        let gps: [CFString: Any] = [
            kCGImagePropertyGPSLatitude: 33.5, kCGImagePropertyGPSLatitudeRef: "S",
            kCGImagePropertyGPSLongitude: 70.6, kCGImagePropertyGPSLongitudeRef: "W",
        ]
        let coordinate = PhotoMetadataReader.parseCoordinate(gps)
        #expect(coordinate?.latitude == -33.5)
        #expect(coordinate?.longitude == -70.6)
    }

    @Test func parsesExifDate() {
        #expect(PhotoMetadataReader.parseDate("2026:10:03 14:05:09") != nil)
        #expect(PhotoMetadataReader.parseDate("invalid") == nil)
    }

    @Test func dataWithoutMetadataGivesNothing() {
        let metadata = PhotoMetadataReader.read(from: Data([0, 1, 2]))
        #expect(metadata.takenAt == nil)
        #expect(metadata.coordinate == nil)
    }
}
