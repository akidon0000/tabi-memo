import Domain
import Foundation
import SharedUI
import Testing
import TestSupport
@testable import TripListFeature

@MainActor
struct TripListViewModelTests {
    private let repository = FakeTripRepository()

    private func makeViewModel(trips: [Trip]) -> (TripListViewModel, Task<Void, Never>) {
        repository.send(trips)
        let viewModel = TripListViewModel(
            observeTrips: ObserveTripsUseCase(tripRepository: repository),
            createTrip: CreateTripUseCase(tripRepository: repository),
            renameTrip: RenameTripUseCase(tripRepository: repository),
            removeTrip: RemoveTripUseCase(tripRepository: repository),
            restoreTrip: RestoreTripUseCase(tripRepository: repository),
            deleteTripPermanently: DeleteTripPermanentlyUseCase(tripRepository: repository),
            purgeExpiredTrips: PurgeExpiredTripsUseCase(tripRepository: repository)
        )
        return (viewModel, Task { await viewModel.start() })
    }

    @Test func sortsByTheChosenOrder() async {
        let old = Trip(name: "b", startedAt: Fixtures.date(minutes: 1), photos: [Fixtures.photo("p", minutes: 100)])
        let new = Trip(name: "a", startedAt: Fixtures.date(minutes: 2), photos: [Fixtures.photo("p", minutes: 50)])
        let (viewModel, task) = makeViewModel(trips: [old, new])
        defer { task.cancel() }
        await waitUntil { viewModel.hasLoaded }

        #expect(viewModel.sortedTrips(.newest).map(\.name) == ["a", "b"])
        #expect(viewModel.sortedTrips(.period).map(\.name) == ["b", "a"])
        #expect(viewModel.sortedTrips(.name).map(\.name) == ["a", "b"])
    }

    @Test func removedTripsLeaveTheListAndAreKeptSeparately() async {
        let active = Trip(name: "a", startedAt: .now)
        let removed = Trip(name: "r", startedAt: .now, removedAt: .now)
        let (viewModel, task) = makeViewModel(trips: [active, removed])
        defer { task.cancel() }
        await waitUntil { viewModel.hasLoaded }

        #expect(viewModel.trips.map(\.id) == [active.id])
        #expect(viewModel.removedTrips.map(\.id) == [removed.id])
    }

    @Test func actionsGoThroughTheRepository() async {
        let trip = Trip(name: "a", startedAt: .now)
        let (viewModel, task) = makeViewModel(trips: [trip])
        defer { task.cancel() }
        await waitUntil { viewModel.hasLoaded }

        #expect(viewModel.create(name: "new") != nil)
        viewModel.rename(trip, to: "renamed")
        viewModel.remove(trip)
        viewModel.restore(trip)
        viewModel.deletePermanently(trip)
        #expect(repository.added.map(\.name) == ["new"])
        #expect(repository.renamed.map(\.name) == ["renamed"])
        #expect(repository.removedAtChanges.count == 2)
        #expect(repository.deleted == [[trip.id]])
    }
}
