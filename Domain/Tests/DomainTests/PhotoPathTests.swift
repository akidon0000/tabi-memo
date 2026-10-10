import Foundation
import Testing
import TestSupport
@testable import Domain

@MainActor
struct PhotoPathTests {
    private let a = Coordinate(latitude: 35.00, longitude: 139.00)
    private let b = Coordinate(latitude: 35.02, longitude: 139.02)
    private let c = Coordinate(latitude: 35.04, longitude: 139.00)

    private func photos() -> [Photo] {
        [
            Fixtures.photo("a", minutes: 1, coordinate: a),
            Fixtures.photo("b", minutes: 2, coordinate: b),
            Fixtures.photo("c", minutes: 3, coordinate: c),
        ]
    }

    @Test func segmentsAreConsecutivePairs() {
        #expect(PhotoPath.segments(of: photos()) == [RouteSegment(from: a, to: b), RouteSegment(from: b, to: c)])
    }

    @Test func segmentsSkipPhotosAtTheSamePlace() {
        let same = [Fixtures.photo("a", minutes: 1, coordinate: a), Fixtures.photo("a2", minutes: 2, coordinate: a)]
        #expect(PhotoPath.segments(of: same).isEmpty)
    }

    @Test func missingSegmentsBecomeStraightLines() {
        #expect(PhotoPath.coordinates(of: photos(), using: [:]) == [a, b, c])
    }

    @Test func foundRoutesReplaceStraightLinesWithoutRepeatingJoints() {
        let corner = Coordinate(latitude: 35.00, longitude: 139.02)
        let paths = [RouteSegment(from: a, to: b): [a, corner, b]]
        #expect(PhotoPath.coordinates(of: photos(), using: paths) == [a, corner, b, c])
    }

    @Test func fewerThanTwoPhotosMakeNoLine() {
        #expect(PhotoPath.coordinates(of: Array(photos().prefix(1)), using: [:]).isEmpty)
    }

    @Test func findRouteFallsBackToStraightLine() async {
        let useCase = FindRouteUseCase(finder: FakeRouteFinder())
        #expect(await useCase.execute(from: a, to: b) == [a, b])
    }

    @Test func findRouteReturnsTheFoundRoute() async {
        let corner = Coordinate(latitude: 35.00, longitude: 139.02)
        let finder = FakeRouteFinder(paths: [RouteSegment(from: a, to: b): [a, corner, b]])
        #expect(await FindRouteUseCase(finder: finder).execute(from: a, to: b) == [a, corner, b])
    }

    @Test func waypointsSplitAPairIntoLegs() {
        let middle = Coordinate(latitude: 35.01, longitude: 139.05)
        let list = photos()
        let edit = RouteEdit(fromPhotoID: list[0].id, toPhotoID: list[1].id, waypoints: [middle])

        let pairs = PhotoPath.pairs(of: list, edits: [edit])
        #expect(pairs[0].stops == [a, middle, b])
        #expect(pairs[0].legs == [RouteSegment(from: a, to: middle), RouteSegment(from: middle, to: b)])
        #expect(pairs[1].waypoints.isEmpty)
        #expect(PhotoPath.coordinates(of: list, edits: [edit], using: [:]) == [a, middle, b, c])
    }

    @Test func aRouteEditForAnotherPairOfPhotosIsIgnored() {
        let list = photos()
        let edit = RouteEdit(fromPhotoID: list[0].id, toPhotoID: list[2].id, waypoints: [b])
        #expect(PhotoPath.coordinates(of: list, edits: [edit], using: [:]) == [a, b, c])
    }
}
