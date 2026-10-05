import Domain
import Foundation
import Testing
import TestSupport

struct TripTests {
    @Test func activePhotosAreSortedAndExcludeRemoved() {
        let trip = Fixtures.trip(photos: [
            Fixtures.photo("late", minutes: 3),
            Fixtures.photo("removed", minutes: 2, removedAt: .now),
            Fixtures.photo("early", minutes: 1),
        ])
        #expect(trip.activePhotos.map(\.title) == ["early", "late"])
        #expect(trip.removedPhotos.map(\.title) == ["removed"])
    }

    @Test func removedPhotosAreNewestFirst() {
        let trip = Fixtures.trip(photos: [
            Fixtures.photo("old", minutes: 1, removedAt: Fixtures.date(minutes: 10)),
            Fixtures.photo("new", minutes: 2, removedAt: Fixtures.date(minutes: 20)),
        ])
        #expect(trip.removedPhotos.map(\.title) == ["new", "old"])
    }

    @Test func neighborFollowsTheActiveOrder() {
        let first = Fixtures.photo("first", minutes: 1)
        let second = Fixtures.photo("second", minutes: 2)
        let trip = Fixtures.trip(photos: [second, first])
        #expect(trip.neighbor(1, of: first.id)?.title == "second")
        #expect(trip.neighbor(-1, of: second.id)?.title == "first")
        #expect(trip.neighbor(1, of: second.id) == nil)
    }
}
