import Domain

/// テスト用の RouteEditRepository。呼ばれた内容を記録する。
@MainActor
public final class FakeRouteEditRepository: RouteEditRepository {
    public private(set) var saved: [(waypoints: [Coordinate], from: Photo.ID, to: Photo.ID, tripID: Trip.ID)] = []

    public init() {}

    public func setWaypoints(_ waypoints: [Coordinate], from fromPhotoID: Photo.ID, to toPhotoID: Photo.ID, in tripID: Trip.ID) throws {
        saved.append((waypoints, fromPhotoID, toPhotoID, tripID))
    }
}
