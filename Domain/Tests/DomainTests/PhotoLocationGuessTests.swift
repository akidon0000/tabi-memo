import Domain
import Foundation
import Testing

struct PhotoLocationGuessTests {
    private func point(_ minutes: Double, _ lat: Double, _ lon: Double) -> PhotoLocationGuess.Point {
        .init(date: Date(timeIntervalSince1970: minutes * 60), coordinate: Coordinate(latitude: lat, longitude: lon))
    }

    @Test func guessIsMidpointOfNeighbors() {
        let center = PhotoLocationGuess.center(
            for: Date(timeIntervalSince1970: 30 * 60),
            among: [point(0, 35.0, 139.0), point(60, 36.0, 140.0)]
        )
        #expect(center == Coordinate(latitude: 35.5, longitude: 139.5))
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
}
