import Foundation
import SwiftData
import Testing
@testable import TabiMemo

struct PhotoDeletionTests {
    private let day: TimeInterval = 86_400

    @Test func expiresAfterSevenDays() {
        let deleted = Date(timeIntervalSince1970: 1_000_000)
        #expect(!PhotoRetention.isExpired(deleted, now: deleted.addingTimeInterval(day * 6.9)))
        #expect(PhotoRetention.isExpired(deleted, now: deleted.addingTimeInterval(day * 7.1)))
    }

    @Test func daysRemainingRoundsUp() {
        let deleted = Date(timeIntervalSince1970: 1_000_000)
        #expect(PhotoRetention.daysRemaining(deleted, now: deleted) == 7)
        #expect(PhotoRetention.daysRemaining(deleted, now: deleted.addingTimeInterval(day * 6.5)) == 1)
        #expect(PhotoRetention.daysRemaining(deleted, now: deleted.addingTimeInterval(day * 9)) == 0)
    }

    @Test func activePhotosExcludeDeletedAndPurgeRemovesOnlyExpired() throws {
        let container = try ModelContainer(
            for: Trip.self, TripPhoto.self, LocationPoint.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let trip = Trip(name: "test")
        context.insert(trip)

        let now = Date()
        func add(deletedAt: Date?) {
            let photo = TripPhoto(imageData: Data(), latitude: 0, longitude: 0)
            photo.deletedAt = deletedAt
            context.insert(photo)
            photo.trip = trip
        }
        add(deletedAt: nil)
        add(deletedAt: now.addingTimeInterval(-day))
        add(deletedAt: now.addingTimeInterval(-day * 8))

        #expect(trip.activePhotos.count == 1)
        #expect(trip.deletedPhotos.count == 2)

        trip.purgeExpiredPhotos(in: context, now: now)
        #expect(trip.photos.count == 2)
        #expect(trip.deletedPhotos.count == 1)
    }
}
