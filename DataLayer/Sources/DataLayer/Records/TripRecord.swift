import Foundation
import SwiftData

/// `Trip` を保存する形。Domain へは `toDomain()` で変換して渡す。
@Model
final class TripRecord {
    var id: UUID
    var name: String
    var startedAt: Date
    var endedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \LocationPointRecord.trip)
    var locationPoints: [LocationPointRecord]

    @Relationship(deleteRule: .cascade, inverse: \PhotoRecord.trip)
    var photos: [PhotoRecord]

    init(id: UUID = UUID(), name: String, startedAt: Date, endedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.startedAt = startedAt
        self.endedAt = endedAt
        locationPoints = []
        photos = []
    }
}
