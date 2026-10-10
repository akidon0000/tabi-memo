import Domain

/// 経路の求め方の偽物。`paths` に入れた区間だけ経路を返し、無い区間は nil(求められなかった)にする。
@MainActor
public final class FakeRouteFinder: RouteFinding {
    public var paths: [RouteSegment: [Coordinate]]
    public private(set) var requests: [RouteSegment] = []

    public init(paths: [RouteSegment: [Coordinate]] = [:]) {
        self.paths = paths
    }

    public func route(from: Coordinate, to: Coordinate) async -> [Coordinate]? {
        let segment = RouteSegment(from: from, to: to)
        requests.append(segment)
        return paths[segment]
    }
}
