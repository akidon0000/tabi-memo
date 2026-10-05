import Foundation

/// 緯度・経度。地図のフレームワークに依存しない、Domain の座標。
public struct Coordinate: Hashable, Sendable {
    public var latitude: Double
    public var longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}
