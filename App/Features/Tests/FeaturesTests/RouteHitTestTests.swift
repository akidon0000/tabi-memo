import CoreGraphics
@testable import TripMapFeature
import Testing

struct RouteHitTestTests {
    private let legs = [
        RouteHitTest.Leg(pair: 0, leg: 0, points: [CGPoint(x: 0, y: 0), CGPoint(x: 100, y: 0)]),
        RouteHitTest.Leg(pair: 0, leg: 1, points: [CGPoint(x: 100, y: 0), CGPoint(x: 100, y: 100)]),
    ]

    @Test func pointNearALegHitsTheLeg() {
        #expect(RouteHitTest.target(at: CGPoint(x: 50, y: 10), handles: [], legs: legs) == .leg(pair: 0, leg: 0))
        #expect(RouteHitTest.target(at: CGPoint(x: 95, y: 60), handles: [], legs: legs) == .leg(pair: 0, leg: 1))
    }

    @Test func pointFarFromEveryLegHitsNothing() {
        #expect(RouteHitTest.target(at: CGPoint(x: 50, y: 80), handles: [], legs: legs) == nil)
    }

    @Test func waypointWinsOverTheLegItSitsOn() {
        let handle = RouteHitTest.Handle(pair: 0, index: 0, point: CGPoint(x: 100, y: 0))
        #expect(RouteHitTest.target(at: CGPoint(x: 90, y: 5), handles: [handle], legs: legs) == .waypoint(pair: 0, index: 0))
    }

    @Test func distanceToAPolylineIsTheShortestDistanceToAnySegment() {
        let line = [CGPoint(x: 0, y: 0), CGPoint(x: 10, y: 0), CGPoint(x: 10, y: 10)]
        #expect(RouteHitTest.distance(from: CGPoint(x: 13, y: 5), to: line) == 3)
    }
}
