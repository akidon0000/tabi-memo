import Domain
import Foundation
import Testing
import TestSupport

@MainActor
struct ObserveTripUseCaseTests {
    @Test func currentTripIsTheNewestWithARoute() async {
        let withoutRoute = Fixtures.trip(photos: [], hasRoute: false)
        let withRoute = Fixtures.trip(photos: [])
        let repository = FakeTripRepository(trips: [withoutRoute, withRoute])
        var iterator = ObserveCurrentTripUseCase(tripRepository: repository).execute().makeAsyncIterator()
        #expect(await iterator.next()??.id == withRoute.id)
    }

    @Test func observingATripFollowsUpdates() async {
        var trip = Fixtures.trip(photos: [])
        let repository = FakeTripRepository(trips: [trip])
        var iterator = ObserveTripUseCase(tripRepository: repository).execute(tripID: trip.id).makeAsyncIterator()
        #expect(await iterator.next()??.photos.isEmpty == true)

        trip.photos = [Fixtures.photo("added", minutes: 1)]
        repository.send([trip])
        #expect(await iterator.next()??.photos.count == 1)

        repository.send([])
        #expect(await iterator.next() == .some(nil))
    }
}
