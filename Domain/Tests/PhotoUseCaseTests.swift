import Domain
import Foundation
import Testing

@MainActor
struct PhotoUseCaseTests {
    private let repository = FakePhotoRepository()

    @Test func addingWithoutOrderKeepsTheDates() throws {
        let trip = Fixtures.trip(photos: [Fixtures.photo("old", minutes: 1)])
        let new = Fixtures.newPhoto("new", minutes: 5)
        try AddPhotosUseCase(photoRepository: repository).execute([new], order: [], to: trip)
        #expect(repository.takenAtChanges.isEmpty)
        #expect(repository.added.first?.photos.first?.takenAt == Fixtures.date(minutes: 5))
        #expect(repository.added.first?.tripID == trip.id)
    }

    @Test func addingWithOrderReassignsExistingAndNewDates() throws {
        let old = Fixtures.photo("old", minutes: 1)
        let trip = Fixtures.trip(photos: [old])
        let new = Fixtures.newPhoto("new", minutes: 5)
        // 新しい写真を、すでにある写真より前に置く。
        try AddPhotosUseCase(photoRepository: repository).execute([new], order: [new.id, old.id], to: trip)
        #expect(repository.takenAtChanges == [[old.id: Fixtures.date(minutes: 5)]])
        #expect(repository.added.first?.photos.first?.takenAt == Fixtures.date(minutes: 1))
    }

    @Test func reorderReassignsDates() throws {
        let first = Fixtures.photo("first", minutes: 1)
        let second = Fixtures.photo("second", minutes: 2)
        let trip = Fixtures.trip(photos: [first, second])
        try ReorderPhotosUseCase(photoRepository: repository).execute(order: [second.id, first.id], in: trip)
        #expect(repository.takenAtChanges == [[second.id: Fixtures.date(minutes: 1), first.id: Fixtures.date(minutes: 2)]])
    }

    @Test func purgeDeletesOnlyExpiredPhotos() throws {
        let now = Date(timeIntervalSince1970: 10_000_000)
        let fresh = Fixtures.photo("fresh", minutes: 1, removedAt: now.addingTimeInterval(-86_400))
        let expired = Fixtures.photo("expired", minutes: 2, removedAt: now.addingTimeInterval(-86_400 * 8))
        let active = Fixtures.photo("active", minutes: 3)
        let trip = Fixtures.trip(photos: [fresh, expired, active])
        try PurgeExpiredPhotosUseCase(photoRepository: repository).execute(in: trip, now: now)
        #expect(repository.deleted == [[expired.id]])
    }

    @Test func purgeDoesNothingWithoutExpiredPhotos() throws {
        let trip = Fixtures.trip(photos: [Fixtures.photo("active", minutes: 1)])
        try PurgeExpiredPhotosUseCase(photoRepository: repository).execute(in: trip)
        #expect(repository.deleted.isEmpty)
    }

    @Test func removeAndRestoreSetRemovedAt() throws {
        let id = UUID()
        let now = Date(timeIntervalSince1970: 1)
        try RemovePhotoUseCase(photoRepository: repository).execute(photoID: id, now: now)
        try RestorePhotoUseCase(photoRepository: repository).execute(photoID: id)
        #expect(repository.removedAtChanges.map(\.date) == [now, nil])
        #expect(repository.removedAtChanges.allSatisfy { $0.photoID == id })
    }
}
