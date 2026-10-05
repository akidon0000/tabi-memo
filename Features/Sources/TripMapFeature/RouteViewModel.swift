import Domain
import Observation

/// 写真を撮影順に結ぶ線の状態。道なりの経路を区間ごとに求めて持ち、経路編集モードで経由点の追加・移動・削除を行う。
@MainActor
@Observable
public final class RouteViewModel {
    /// 経路編集モード中か。
    var isEditing = false
    /// 区間ごとの道なりの経路。まだ求めていない区間は、線が直線になる。
    private(set) var legPaths: [RouteSegment: [Coordinate]] = [:]

    private var routeTask: Task<Void, Never>?
    private let findRoute: FindRouteUseCase
    private let setWaypoints: SetRouteWaypointsUseCase

    public init(findRoute: FindRouteUseCase, setWaypoints: SetRouteWaypointsUseCase) {
        self.findRoute = findRoute
        self.setWaypoints = setWaypoints
    }

    /// 地図に引く、写真を結ぶ線の座標。
    func path(of trip: Trip) -> [Coordinate] {
        PhotoPath.coordinates(of: trip.activePhotos, edits: trip.routeEdits, using: legPaths)
    }

    /// 写真の組ごとの区間。編集モードで、経由点と、線のどこを掴んだかを調べるのに使う。
    func pairs(of trip: Trip) -> [PhotoPath.Pair] {
        PhotoPath.pairs(of: trip.activePhotos, edits: trip.routeEdits)
    }

    /// まだ求めていない区間の道なりの経路を、順に求める。求められなかった区間は直線のまま覚える(再起動までは求め直さない)。
    func refresh(for trip: Trip) {
        routeTask?.cancel()
        let missing = PhotoPath.segments(of: trip.activePhotos, edits: trip.routeEdits).filter { legPaths[$0] == nil }
        guard !missing.isEmpty else { return }
        routeTask = Task {
            for segment in missing {
                let path = await findRoute.execute(from: segment.from, to: segment.to)
                if Task.isCancelled { return }
                legPaths[segment] = path
            }
        }
    }

    /// 区間 `leg` の途中に、通る点を足す。
    func insertWaypoint(_ coordinate: Coordinate, pair: PhotoPath.Pair, leg: Int, in trip: Trip) {
        var waypoints = pair.waypoints
        waypoints.insert(coordinate, at: min(leg, waypoints.count))
        save(waypoints, for: pair, in: trip)
    }

    func moveWaypoint(at index: Int, to coordinate: Coordinate, pair: PhotoPath.Pair, in trip: Trip) {
        guard pair.waypoints.indices.contains(index) else { return }
        var waypoints = pair.waypoints
        waypoints[index] = coordinate
        save(waypoints, for: pair, in: trip)
    }

    func removeWaypoint(at index: Int, pair: PhotoPath.Pair, in trip: Trip) {
        guard pair.waypoints.indices.contains(index) else { return }
        var waypoints = pair.waypoints
        waypoints.remove(at: index)
        save(waypoints, for: pair, in: trip)
    }

    private func save(_ waypoints: [Coordinate], for pair: PhotoPath.Pair, in trip: Trip) {
        try? setWaypoints.execute(waypoints: waypoints, from: pair.fromPhotoID, to: pair.toPhotoID, in: trip.id)
    }
}
