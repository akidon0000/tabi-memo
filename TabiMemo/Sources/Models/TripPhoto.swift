import Foundation
import SwiftData

@Model
final class TripPhoto {
    var id: UUID
    @Attribute(.externalStorage) var imageData: Data
    var latitude: Double
    var longitude: Double
    var takenAt: Date
    /// EXIF/現在地から位置を取得できず、ユーザーが地図タップで手動配置した場合に true。
    var isLocationManuallyPlaced: Bool
    /// 写真のタイトル。
    var title: String = ""
    /// 写真に添えるメモ。
    var memo: String = ""
    var trip: Trip?

    init(
        imageData: Data,
        latitude: Double,
        longitude: Double,
        takenAt: Date = .now,
        isLocationManuallyPlaced: Bool = false,
        title: String = "",
        memo: String = ""
    ) {
        id = UUID()
        self.imageData = imageData
        self.latitude = latitude
        self.longitude = longitude
        self.takenAt = takenAt
        self.isLocationManuallyPlaced = isLocationManuallyPlaced
        self.title = title
        self.memo = memo
    }
}
