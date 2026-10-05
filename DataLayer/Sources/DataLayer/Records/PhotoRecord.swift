import Foundation
import SwiftData

/// `Photo` を保存する形。
@Model
final class PhotoRecord {
    var id: UUID
    @Attribute(.externalStorage) var imageData: Data
    var latitude: Double
    var longitude: Double
    var takenAt: Date
    var isLocationManuallyPlaced: Bool
    var title: String
    var memo: String
    var removedAt: Date?
    var trip: TripRecord?

    init(
        id: UUID,
        imageData: Data,
        latitude: Double,
        longitude: Double,
        takenAt: Date,
        isLocationManuallyPlaced: Bool,
        title: String,
        memo: String,
        removedAt: Date? = nil
    ) {
        self.id = id
        self.imageData = imageData
        self.latitude = latitude
        self.longitude = longitude
        self.takenAt = takenAt
        self.isLocationManuallyPlaced = isLocationManuallyPlaced
        self.title = title
        self.memo = memo
        self.removedAt = removedAt
    }
}
