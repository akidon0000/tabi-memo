import Foundation

/// 位置のない写真を地図で指定するとき、最初に地図を寄せる場所を、撮影時刻が前後する写真から求める。
public enum PhotoLocationGuess {
    public struct Point: Hashable, Sendable {
        public var date: Date
        public var coordinate: Coordinate

        public init(date: Date, coordinate: Coordinate) {
            self.date = date
            self.coordinate = coordinate
        }
    }

    /// 直前と直後の写真の中間点。片側しかなければその位置。1枚もなければ nil。
    public static func center(for date: Date, among points: [Point]) -> Coordinate? {
        let before = points.filter { $0.date <= date }.max { $0.date < $1.date }
        let after = points.filter { $0.date > date }.min { $0.date < $1.date }
        switch (before, after) {
        case let (before?, after?):
            return Coordinate(
                latitude: (before.coordinate.latitude + after.coordinate.latitude) / 2,
                longitude: (before.coordinate.longitude + after.coordinate.longitude) / 2
            )
        case let (before?, nil): return before.coordinate
        case let (nil, after?): return after.coordinate
        case (nil, nil): return nil
        }
    }
}
