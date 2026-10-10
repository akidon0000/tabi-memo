import Foundation

/// 編集画面で書き換えられる項目。
public struct PhotoEdit: Hashable, Sendable {
    public var takenAt: Date
    public var coordinate: Coordinate
    public var isLocationManuallyPlaced: Bool
    public var title: String
    public var memo: String

    public init(takenAt: Date, coordinate: Coordinate, isLocationManuallyPlaced: Bool, title: String, memo: String) {
        self.takenAt = takenAt
        self.coordinate = coordinate
        self.isLocationManuallyPlaced = isLocationManuallyPlaced
        self.title = title
        self.memo = memo
    }

    /// いまの写真の内容から作る(編集画面の初期値)。
    public init(_ photo: Photo) {
        self.init(
            takenAt: photo.takenAt,
            coordinate: photo.coordinate,
            isLocationManuallyPlaced: photo.isLocationManuallyPlaced,
            title: photo.title,
            memo: photo.memo
        )
    }
}
