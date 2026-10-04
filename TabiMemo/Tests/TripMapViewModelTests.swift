import Domain
import Foundation
@testable import TabiMemo
import Testing

@MainActor
struct TripMapViewModelTests {
    private let photoRepository = FakePhotoRepository()
    private let first = Fixtures.photo("first", minutes: 1)
    private let second = Fixtures.photo("second", minutes: 2)

    private func makeViewModel(photos: [Photo]) -> (TripMapViewModel, Task<Void, Never>) {
        let tripRepository = FakeTripRepository(trips: [Fixtures.trip(photos: photos)])
        let viewModel = TripMapViewModel(
            observeCurrentTrip: ObserveCurrentTripUseCase(tripRepository: tripRepository),
            purgeExpiredPhotos: PurgeExpiredPhotosUseCase(photoRepository: photoRepository),
            removePhoto: RemovePhotoUseCase(photoRepository: photoRepository)
        )
        let task = Task { await viewModel.start() }
        return (viewModel, task)
    }

    @Test func removingSelectsTheNextPhoto() async {
        let (viewModel, task) = makeViewModel(photos: [first, second])
        defer { task.cancel() }
        await waitUntil { viewModel.trip != nil }

        viewModel.select(first)
        let next = viewModel.removeSelectedPhoto()
        #expect(next?.id == second.id)
        #expect(viewModel.selectedPhotoID == second.id)
        #expect(photoRepository.removedAtChanges.map(\.photoID) == [first.id])
    }

    @Test func removingTheLastPhotoClosesThePanel() async {
        let (viewModel, task) = makeViewModel(photos: [first])
        defer { task.cancel() }
        await waitUntil { viewModel.trip != nil }

        viewModel.select(first)
        #expect(viewModel.removeSelectedPhoto() == nil)
        #expect(viewModel.selectedPhotoID == nil)
    }

    @Test func expiredPhotosArePurgedOnceOnStart() async {
        let expired = Fixtures.photo("expired", minutes: 3, removedAt: Date(timeIntervalSince1970: 0))
        let (viewModel, task) = makeViewModel(photos: [first, expired])
        defer { task.cancel() }
        await waitUntil { viewModel.trip != nil }
        #expect(photoRepository.deleted == [[expired.id]])
    }
}
