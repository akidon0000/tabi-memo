import Domain
import Foundation
@testable import TripMapFeature
import Testing
import TestSupport

@MainActor
struct TripMapViewModelTests {
    private let photoRepository = FakePhotoRepository()
    private let first = Fixtures.photo("first", minutes: 1)
    private let second = Fixtures.photo("second", minutes: 2)

    private let routeFinder = FakeRouteFinder()

    private func makeViewModel(photos: [Photo]) -> (TripMapViewModel, Task<Void, Never>) {
        let tripRepository = FakeTripRepository(trips: [Fixtures.trip(photos: photos)])
        let viewModel = TripMapViewModel(
            observeCurrentTrip: ObserveCurrentTripUseCase(tripRepository: tripRepository),
            purgeExpiredPhotos: PurgeExpiredPhotosUseCase(photoRepository: photoRepository),
            removePhoto: RemovePhotoUseCase(photoRepository: photoRepository),
            findRoute: FindRouteUseCase(finder: routeFinder)
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

    @Test func firstPhotoInShootingOrderIsSelectedOnOpen() async {
        let (viewModel, task) = makeViewModel(photos: [second, first])
        defer { task.cancel() }
        await waitUntil { viewModel.selectedPhotoID != nil }
        #expect(viewModel.selectedPhotoID == first.id)
    }

    @Test func nothingIsSelectedWhenThereAreNoPhotos() async {
        let (viewModel, task) = makeViewModel(photos: [])
        defer { task.cancel() }
        await waitUntil { viewModel.trip != nil }
        #expect(viewModel.selectedPhotoID == nil)
    }

    @Test func photoPathUsesTheRouteFoundAlongTheRoad() async {
        let a = Coordinate(latitude: 35.00, longitude: 139.00)
        let b = Coordinate(latitude: 35.02, longitude: 139.02)
        let corner = Coordinate(latitude: 35.00, longitude: 139.02)
        routeFinder.paths = [RouteSegment(from: a, to: b): [a, corner, b]]
        let (viewModel, task) = makeViewModel(photos: [
            Fixtures.photo("a", minutes: 1, coordinate: a),
            Fixtures.photo("b", minutes: 2, coordinate: b),
        ])
        defer { task.cancel() }

        await waitUntil { viewModel.photoPath.count == 3 }
        #expect(viewModel.photoPath == [a, corner, b])
    }

    @Test func photoPathFallsBackToAStraightLineWhenNoRouteIsFound() async {
        let a = Coordinate(latitude: 35.00, longitude: 139.00)
        let b = Coordinate(latitude: 35.02, longitude: 139.02)
        let (viewModel, task) = makeViewModel(photos: [
            Fixtures.photo("a", minutes: 1, coordinate: a),
            Fixtures.photo("b", minutes: 2, coordinate: b),
        ])
        defer { task.cancel() }

        await waitUntil { !routeFinder.requests.isEmpty }
        #expect(viewModel.photoPath == [a, b])
    }
}
