import Foundation

/// アプリ内カメラで撮った1枚。追加フォームへ渡す前の、撮影した時点の内容。
public struct CapturedPhoto: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var imageData: Data
    public var takenAt: Date
    /// 撮った瞬間の現在地。位置情報が使えなかったときは nil(追加フォームで地図に置く)。
    public var coordinate: Coordinate?

    public init(id: UUID = UUID(), imageData: Data, takenAt: Date, coordinate: Coordinate?) {
        self.id = id
        self.imageData = imageData
        self.takenAt = takenAt
        self.coordinate = coordinate
    }
}
