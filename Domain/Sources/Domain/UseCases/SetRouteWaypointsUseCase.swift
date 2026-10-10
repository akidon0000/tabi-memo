import Foundation

/// 写真の組の間の線が通る点(経由点)を、保存する。空にすると自動の経路に戻る。
@MainActor
public struct SetRouteWaypointsUseCase {
    private let routeEditRepository: any RouteEditRepository

    public init(routeEditRepository: any RouteEditRepository) {
        self.routeEditRepository = routeEditRepository
    }

    public func execute(waypoints: [Coordinate], from fromPhotoID: Photo.ID, to toPhotoID: Photo.ID, in tripID: Trip.ID) throws {
        try routeEditRepository.setWaypoints(waypoints, from: fromPhotoID, to: toPhotoID, in: tripID)
    }
}
