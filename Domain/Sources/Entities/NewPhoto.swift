import Foundation

/// これから保存する写真。追加の流れで入力した内容。
public struct NewPhoto: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var imageData: Data
    public var coordinate: Coordinate
    public var takenAt: Date
    public var isLocationManuallyPlaced: Bool
    public var title: String
    public var memo: String

    public init(
        id: UUID = UUID(),
        imageData: Data,
        coordinate: Coordinate,
        takenAt: Date,
        isLocationManuallyPlaced: Bool,
        title: String,
        memo: String
    ) {
        self.id = id
        self.imageData = imageData
        self.coordinate = coordinate
        self.takenAt = takenAt
        self.isLocationManuallyPlaced = isLocationManuallyPlaced
        self.title = title
        self.memo = memo
    }
}
