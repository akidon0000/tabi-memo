import Foundation
import SwiftData

@Model
final class LocationPoint {
    var id: UUID
    var latitude: Double
    var longitude: Double
    var altitude: Double?
    var timestamp: Date
    var trip: Trip?

    init(latitude: Double, longitude: Double, altitude: Double? = nil, timestamp: Date = .now) {
        id = UUID()
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.timestamp = timestamp
    }
}
