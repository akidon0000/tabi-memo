import Foundation

/// 写真を結ぶ線の直し(経由点)の書き込み。変わった内容は `TripRepository.observeTrips()` から流れてくる。
@MainActor
public protocol RouteEditRepository {
    /// 写真の組の経由点を置き換える。空を渡すと、その組の直しを消す(自動の経路に戻る)。
    func setWaypoints(_ waypoints: [Coordinate], from fromPhotoID: Photo.ID, to toPhotoID: Photo.ID, in tripID: Trip.ID) throws
}
