@testable import DataLayer
import Domain
import Foundation
import SwiftData
import Testing

@MainActor
struct SwiftDataRepositoryTests {
    private let store: SwiftDataStore
    private let trips: SwiftDataTripRepository
    private let photos: SwiftDataPhotoRepository

    init() throws {
        store = try SwiftDataStore.inMemory()
        try store.seedSampleTripIfEmpty()
        trips = try SwiftDataTripRepository(store: store)
        photos = SwiftDataPhotoRepository(store: store)
    }

    @Test(.timeLimit(.minutes(1)))
    func seededTripIsObservedAsDomainValue() async throws {
        var iterator = trips.observeTrips().makeAsyncIterator()
        let trip = try #require(await iterator.next()?.first)
        #expect(trip.name == "渋谷から代々木公園散歩")
        #expect(trip.locationPoints.count == 30)
        #expect(trip.activePhotos.count == 3)
    }

    @Test(.timeLimit(.minutes(1)))
    func savingPhotosPushesANewValue() async throws {
        var iterator = trips.observeTrips().makeAsyncIterator()
        let trip = try #require(await iterator.next()?.first)

        let new = NewPhoto(
            imageData: Data(), coordinate: Coordinate(latitude: 1, longitude: 2), takenAt: .now,
            isLocationManuallyPlaced: true, title: "added", memo: "memo"
        )
        try photos.add([new], to: trip.id)
        let afterAdd = try #require(await firstValue(of: &iterator) { $0.first?.photos.contains { $0.id == new.id } == true })
        let added = try #require(afterAdd.first?.photos.first { $0.id == new.id })
        #expect(added.title == "added")
        #expect(added.coordinate == Coordinate(latitude: 1, longitude: 2))

        try photos.setRemovedAt(.now, for: new.id)
        let afterRemove = await firstValue(of: &iterator) { $0.first?.removedPhotos.map(\.id) == [new.id] }
        #expect(afterRemove != nil)
    }

    @Test(.timeLimit(.minutes(1)))
    func updateReorderAndDeleteAreSaved() async throws {
        var iterator = trips.observeTrips().makeAsyncIterator()
        let trip = try #require(await iterator.next()?.first)
        let first = trip.activePhotos[0]
        let edit = PhotoEdit(
            takenAt: first.takenAt, coordinate: first.coordinate, isLocationManuallyPlaced: true, title: "edited", memo: "m"
        )
        try photos.update(first.id, with: edit)
        try photos.setTakenAt([first.id: .distantFuture])
        try photos.delete([trip.activePhotos[1].id])

        let latest = try #require(try savedTrip())
        #expect(latest.activePhotos.count == 2)
        #expect(latest.activePhotos.last?.title == "edited")
    }

    /// 条件を満たす値が流れてくるまで読み進める。保存の途中の状態が流れることがあるので、「次の値」ではなく条件で待つ。
    private func firstValue(
        of iterator: inout AsyncStream<[Trip]>.Iterator,
        where predicate: ([Trip]) -> Bool
    ) async -> [Trip]? {
        while let value = await iterator.next(isolation: #isolation) {
            if predicate(value) { return value }
        }
        return nil
    }

    /// 保存した直後の内容。ストリームを待たずに、保存先から直接読む。
    private func savedTrip() throws -> Trip? {
        try store.context.fetch(FetchDescriptor<TripRecord>()).first?.toDomain()
    }

    @Test func addingToAMissingTripThrows() {
        #expect(throws: SwiftDataStoreError.self) {
            try photos.add([], to: UUID())
        }
    }
}
