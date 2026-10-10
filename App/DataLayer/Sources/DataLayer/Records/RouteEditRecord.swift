import Foundation
import SwiftData

/// `RouteEdit` を保存する形。座標は、緯度と経度を別の配列で持つ(同じ順)。
@Model
final class RouteEditRecord {
    var id: UUID
    var fromPhotoID: UUID
    var toPhotoID: UUID
    var latitudes: [Double]
    var longitudes: [Double]
    var trip: TripRecord?

    init(id: UUID = UUID(), fromPhotoID: UUID, toPhotoID: UUID, latitudes: [Double], longitudes: [Double]) {
        self.id = id
        self.fromPhotoID = fromPhotoID
        self.toPhotoID = toPhotoID
        self.latitudes = latitudes
        self.longitudes = longitudes
    }
}
