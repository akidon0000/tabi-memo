import Foundation
import SwiftData
import Testing
@testable import TabiMemo

struct PhotoOrderTests {
    private func makeTrip() throws -> (Trip, [TripPhoto]) {
        let container = try ModelContainer(
            for: Trip.self, TripPhoto.self, LocationPoint.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let trip = Trip(name: "test")
        context.insert(trip)
        let photos = (0..<3).map { index -> TripPhoto in
            let photo = TripPhoto(imageData: Data(), latitude: 0, longitude: 0,
                                  takenAt: Date(timeIntervalSince1970: Double(index + 1) * 1000), title: "p\(index)")
            context.insert(photo)
            photo.trip = trip
            return photo
        }
        return (trip, photos)
    }

    @Test func applyOrderReassignsSortedDates() throws {
        let (trip, photos) = try makeTrip()
        trip.applyOrder([photos[2], photos[0], photos[1]])
        #expect(trip.sortedActivePhotos.map(\.title) == ["p2", "p0", "p1"])
        // 日時の集合そのものは変わらない。
        #expect(Set(trip.activePhotos.map(\.takenAt)) == Set([1000, 2000, 3000].map { Date(timeIntervalSince1970: $0) }))
    }

    @Test func moveToTargetPutsPhotoAtTargetPosition() throws {
        let (trip, photos) = try makeTrip()
        trip.move(photos[0], to: photos[2])
        #expect(trip.sortedActivePhotos.map(\.title) == ["p1", "p2", "p0"])
    }

    @Test func deletedPhotosAreLeftOutOfTheOrder() throws {
        let (trip, photos) = try makeTrip()
        photos[1].deletedAt = .now
        #expect(trip.sortedActivePhotos.map(\.title) == ["p0", "p2"])
    }
}
