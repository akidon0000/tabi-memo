import Domain
import Foundation
@testable import PhotoListFeature
import Testing
import TestSupport

@MainActor
struct PhotoListViewModelTests {
    private let photoRepository = FakePhotoRepository()
    private let a = Fixtures.photo("a", minutes: 1)
    private let b = Fixtures.photo("b", minutes: 2)
    private let c = Fixtures.photo("c", minutes: 3)

    private func makeViewModel() async -> (PhotoListViewModel, Task<Void, Never>) {
        let trip = Fixtures.trip(photos: [a, b, c])
        let viewModel = PhotoListViewModel(
            tripID: trip.id,
            observeTrip: ObserveTripUseCase(tripRepository: FakeTripRepository(trips: [trip])),
            reorderPhotos: ReorderPhotosUseCase(photoRepository: photoRepository),
            removePhoto: RemovePhotoUseCase(photoRepository: photoRepository)
        )
        let task = Task { await viewModel.start() }
        await waitUntil { viewModel.trip != nil }
        return (viewModel, task)
    }

    @Test func movingInTheListReassignsDates() async {
        let (viewModel, task) = await makeViewModel()
        defer { task.cancel() }
        // c を先頭へ。
        viewModel.move(fromOffsets: IndexSet(integer: 2), toOffset: 0)
        #expect(photoRepository.takenAtChanges == [[
            c.id: Fixtures.date(minutes: 1), a.id: Fixtures.date(minutes: 2), b.id: Fixtures.date(minutes: 3),
        ]])
    }

    @Test func droppingOnAnotherPhotoMovesToItsPosition() async {
        let (viewModel, task) = await makeViewModel()
        defer { task.cancel() }
        #expect(viewModel.move(a.id, to: c))
        #expect(photoRepository.takenAtChanges == [[
            b.id: Fixtures.date(minutes: 1), c.id: Fixtures.date(minutes: 2), a.id: Fixtures.date(minutes: 3),
        ]])
        #expect(!viewModel.move(UUID(), to: c))
    }
}
