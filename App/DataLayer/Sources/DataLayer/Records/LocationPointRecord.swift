import Foundation
import SwiftData

/// `LocationPoint` を保存する形。
@Model
final class LocationPointRecord {
    var id: UUID
    var latitude: Double
    var longitude: Double
    var altitude: Double?
    var timestamp: Date
    var trip: TripRecord?

    init(id: UUID = UUID(), latitude: Double, longitude: Double, altitude: Double? = nil, timestamp: Date) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.timestamp = timestamp
    }
}
