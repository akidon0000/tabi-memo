import Foundation
import SwiftData

@Model
final class Trip {
    var id: UUID
    var name: String
    var startedAt: Date
    var endedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \LocationPoint.trip)
    var locationPoints: [LocationPoint]

    @Relationship(deleteRule: .cascade, inverse: \TripPhoto.trip)
    var photos: [TripPhoto]

    var isActive: Bool { endedAt == nil }

    init(name: String, startedAt: Date = .now) {
        id = UUID()
        self.name = name
        self.startedAt = startedAt
        endedAt = nil
        locationPoints = []
        photos = []
    }
}
