import Foundation

/// 写真データに入っている、使えるメタデータ。無いものは nil。
public struct PhotoMetadata: Hashable, Sendable {
    public var takenAt: Date?
    public var coordinate: Coordinate?

    public init(takenAt: Date? = nil, coordinate: Coordinate? = nil) {
        self.takenAt = takenAt
        self.coordinate = coordinate
    }
}
