import Domain
import Observation

/// 写真を撮影順に結ぶ線の状態。道なりの経路を区間ごとに求めて持ち、経路編集モードで経由点の追加・移動・削除を行う。
@MainActor
@Observable
public final class RouteViewModel {
    /// 経路編集モード中か。
    private(set) var isEditing = false
    /// 編集モードに入ってからの、直す前の経由点(新しい順に積む)。「1つ戻す」「すべて戻す」に使う。
    private var history: [Step] = []
    /// 区間ごとの道なりの経路。まだ求めていない区間は、線が直線になる。
    private(set) var legPaths: [RouteSegment: [Coordinate]] = [:]

    /// 1回の編集。どの組の経由点を、どう直す前の状態に戻すか。
    private struct Step {
        let fromPhotoID: Photo.ID
        let toPhotoID: Photo.ID
        let tripID: Trip.ID
        let before: [Coordinate]
    }

    private var routeTask: Task<Void, Never>?
    private let findRoute: FindRouteUseCase
    private let setWaypoints: SetRouteWaypointsUseCase

    public init(findRoute: FindRouteUseCase, setWaypoints: SetRouteWaypointsUseCase) {
        self.findRoute = findRoute
        self.setWaypoints = setWaypoints
    }

    var canUndo: Bool { !history.isEmpty }

    func beginEditing() {
        history = []
        isEditing = true
    }

    func finishEditing() {
        history = []
        isEditing = false
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

    /// 直す前に戻す。最後の1回だけ(編集モードに入る前より前には戻らない)。
    func undo() {
        guard let step = history.popLast() else { return }
        restore(step)
    }

    /// 編集モードに入ったときの状態まで、すべて戻す。
    func undoAll() {
        // 同じ組を何度直していても、いちばん古い「直す前」だけを書き戻す(`history` は古い順。重なったら先のものを残す)。
        let oldestFirst = Dictionary(history.map { (Pair(from: $0.fromPhotoID, to: $0.toPhotoID), $0) }, uniquingKeysWith: { first, _ in first })
        history = []
        for step in oldestFirst.values { restore(step) }
    }

    private struct Pair: Hashable {
        let from: Photo.ID
        let to: Photo.ID
    }

    private func restore(_ step: Step) {
        try? setWaypoints.execute(waypoints: step.before, from: step.fromPhotoID, to: step.toPhotoID, in: step.tripID)
    }

    private func save(_ waypoints: [Coordinate], for pair: PhotoPath.Pair, in trip: Trip) {
        history.append(Step(fromPhotoID: pair.fromPhotoID, toPhotoID: pair.toPhotoID, tripID: trip.id, before: pair.waypoints))
        try? setWaypoints.execute(waypoints: waypoints, from: pair.fromPhotoID, to: pair.toPhotoID, in: trip.id)
    }
}
