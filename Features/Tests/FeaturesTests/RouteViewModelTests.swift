import Domain
import Foundation
@testable import TripMapFeature
import Testing
import TestSupport

@MainActor
struct RouteViewModelTests {
    private let a = Coordinate(latitude: 35.00, longitude: 139.00)
    private let b = Coordinate(latitude: 35.02, longitude: 139.02)
    private let corner = Coordinate(latitude: 35.00, longitude: 139.02)
    private let finder = FakeRouteFinder()
    private let repository = FakeRouteEditRepository()

    private func makeViewModel() -> RouteViewModel {
        RouteViewModel(
            findRoute: FindRouteUseCase(finder: finder),
            setWaypoints: SetRouteWaypointsUseCase(routeEditRepository: repository)
        )
    }

    private func makeTrip(edits: [RouteEdit] = []) -> Trip {
        var trip = Fixtures.trip(photos: [
            Fixtures.photo("a", minutes: 1, coordinate: a),
            Fixtures.photo("b", minutes: 2, coordinate: b),
        ])
        trip.routeEdits = edits
        return trip
    }

    @Test func pathUsesTheRouteFoundAlongTheRoad() async {
        finder.paths = [RouteSegment(from: a, to: b): [a, corner, b]]
        let viewModel = makeViewModel()
        let trip = makeTrip()

        viewModel.refresh(for: trip)
        await waitUntil { viewModel.path(of: trip).count == 3 }
        #expect(viewModel.path(of: trip) == [a, corner, b])
    }

    @Test func pathFallsBackToAStraightLineWhenNoRouteIsFound() async {
        let viewModel = makeViewModel()
        let trip = makeTrip()

        viewModel.refresh(for: trip)
        await waitUntil { !finder.requests.isEmpty }
        #expect(viewModel.path(of: trip) == [a, b])
    }

    @Test func routesAreFoundPerLegThroughTheWaypoints() async {
        var trip = makeTrip()
        trip.routeEdits = [RouteEdit(fromPhotoID: trip.photos[0].id, toPhotoID: trip.photos[1].id, waypoints: [corner])]
        let viewModel = makeViewModel()

        viewModel.refresh(for: trip)
        await waitUntil { finder.requests.count == 2 }
        #expect(Set(finder.requests) == [RouteSegment(from: a, to: corner), RouteSegment(from: corner, to: b)])
        #expect(viewModel.path(of: trip) == [a, corner, b])
    }

    @Test func insertingAWaypointSavesItInTheLegsPlace() {
        let viewModel = makeViewModel()
        let trip = makeTrip()
        let pair = viewModel.pairs(of: trip)[0]

        viewModel.insertWaypoint(corner, pair: pair, leg: 0, in: trip)
        #expect(repository.saved.map(\.waypoints) == [[corner]])
        #expect(repository.saved.first?.from == pair.fromPhotoID)
        #expect(repository.saved.first?.to == pair.toPhotoID)
    }

    @Test func movingAndRemovingWaypointsSaveTheNewList() {
        let viewModel = makeViewModel()
        var trip = makeTrip()
        trip.routeEdits = [RouteEdit(fromPhotoID: trip.photos[0].id, toPhotoID: trip.photos[1].id, waypoints: [corner, b])]
        let pair = viewModel.pairs(of: trip)[0]

        viewModel.moveWaypoint(at: 0, to: a, pair: pair, in: trip)
        viewModel.removeWaypoint(at: 1, pair: pair, in: trip)
        #expect(repository.saved.map(\.waypoints) == [[a, b], [corner]])
    }

    @Test func undoRestoresTheWaypointsBeforeTheLastEdit() {
        let viewModel = makeViewModel()
        let trip = makeTrip()
        let pair = viewModel.pairs(of: trip)[0]
        viewModel.beginEditing()
        #expect(!viewModel.canUndo)

        viewModel.insertWaypoint(corner, pair: pair, leg: 0, in: trip)
        #expect(viewModel.canUndo)
        viewModel.undo()

        #expect(repository.saved.map(\.waypoints) == [[corner], []])
        #expect(!viewModel.canUndo)
    }

    @Test func undoAllRestoresTheStateWhenEditingBegan() {
        let viewModel = makeViewModel()
        let trip = makeTrip()
        let pair = viewModel.pairs(of: trip)[0]
        let other = Coordinate(latitude: 35.01, longitude: 139.01)
        viewModel.beginEditing()

        viewModel.insertWaypoint(corner, pair: pair, leg: 0, in: trip)
        var edited = pair
        edited.waypoints = [corner]
        viewModel.insertWaypoint(other, pair: edited, leg: 1, in: trip)
        viewModel.undoAll()

        // 2回直したあと、書き戻すのは「編集を始める前」の1回だけ。
        #expect(repository.saved.last?.waypoints == [])
        #expect(repository.saved.count == 3)
        #expect(!viewModel.canUndo)
    }

    @Test func finishingEditingClearsTheHistory() {
        let viewModel = makeViewModel()
        let trip = makeTrip()
        viewModel.beginEditing()
        viewModel.insertWaypoint(corner, pair: viewModel.pairs(of: trip)[0], leg: 0, in: trip)

        viewModel.finishEditing()
        #expect(!viewModel.canUndo)
        #expect(!viewModel.isEditing)
    }
}
