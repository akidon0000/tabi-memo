import Domain
import Foundation
import Testing
import TestSupport

@MainActor
struct TripUseCaseTests {
    private let repository = FakeTripRepository()

    @Test func creatingATripTrimsTheNameAndFallsBackToADefault() throws {
        let id = try CreateTripUseCase(tripRepository: repository).execute(name: "  京都 ")
        _ = try CreateTripUseCase(tripRepository: repository).execute(name: "   ")
        #expect(repository.added.map(\.name) == ["京都", "新しいトリップ"])
        #expect(repository.added.first?.id == id)
        #expect(repository.added.allSatisfy { $0.photos.isEmpty })
    }

    @Test func renamingIgnoresAnEmptyName() throws {
        let id = UUID()
        let rename = RenameTripUseCase(tripRepository: repository)
        try rename.execute(tripID: id, name: " 沖縄 ")
        try rename.execute(tripID: id, name: "  ")
        #expect(repository.renamed.map(\.name) == ["沖縄"])
    }

    @Test func removingAndRestoringSetsAndClearsTheDate() throws {
        let id = UUID()
        let now = Date.now
        try RemoveTripUseCase(tripRepository: repository).execute(tripID: id, now: now)
        try RestoreTripUseCase(tripRepository: repository).execute(tripID: id)
        #expect(repository.removedAtChanges.map(\.date) == [now, nil])
    }

    @Test func purgingDeletesOnlyExpiredTrips() throws {
        let now = Date.now
        let expired = Trip(name: "old", startedAt: now, removedAt: now.addingTimeInterval(-86_400 * Double(TripRetention.days + 1)))
        let recent = Trip(name: "recent", startedAt: now, removedAt: now.addingTimeInterval(-86_400))
        let active = Trip(name: "active", startedAt: now)
        try PurgeExpiredTripsUseCase(tripRepository: repository).execute(in: [expired, recent, active], now: now)
        #expect(repository.deleted == [[expired.id]])
    }

    @Test func observingSplitsActiveAndRemovedTrips() async {
        let now = Date.now
        let active = Trip(name: "a", startedAt: now)
        let older = Trip(name: "o", startedAt: now, removedAt: now.addingTimeInterval(-100))
        let newer = Trip(name: "n", startedAt: now, removedAt: now.addingTimeInterval(-10))
        let repository = FakeTripRepository(trips: [active, older, newer])
        var iterator = ObserveTripsUseCase(tripRepository: repository).execute().makeAsyncIterator()
        let value = await iterator.next()
        #expect(value?.active.map(\.id) == [active.id])
        #expect(value?.removed.map(\.id) == [newer.id, older.id])
    }

    @Test func periodIsFirstToLastPhotoDayOrTheStartDayWithoutPhotos() {
        let empty = Trip(name: "e", startedAt: Fixtures.date(minutes: 5))
        #expect(empty.period == Fixtures.date(minutes: 5)...Fixtures.date(minutes: 5))
        let trip = Fixtures.trip(photos: [Fixtures.photo("b", minutes: 30), Fixtures.photo("a", minutes: 10)])
        #expect(trip.period == Fixtures.date(minutes: 10)...Fixtures.date(minutes: 30))
    }
}
