import Foundation

/// 地図に置く写真1枚。
public struct Photo: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var imageData: Data
    public var coordinate: Coordinate
    public var takenAt: Date
    /// 写真に位置情報が無く、ユーザーが地図でピンを置いて決めたとき true。
    public var isLocationManuallyPlaced: Bool
    public var title: String
    public var memo: String
    /// 取り除いた日時。nil なら地図に出る。値があれば「最近取り除いた項目」に入り、保持期間を過ぎると完全に消す。
    public var removedAt: Date?

    public var isRemoved: Bool { removedAt != nil }

    public init(
        id: UUID = UUID(),
        imageData: Data,
        coordinate: Coordinate,
        takenAt: Date,
        isLocationManuallyPlaced: Bool = false,
        title: String = "",
        memo: String = "",
        removedAt: Date? = nil
    ) {
        self.id = id
        self.imageData = imageData
        self.coordinate = coordinate
        self.takenAt = takenAt
        self.isLocationManuallyPlaced = isLocationManuallyPlaced
        self.title = title
        self.memo = memo
        self.removedAt = removedAt
    }
}
