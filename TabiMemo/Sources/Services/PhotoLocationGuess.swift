import CoreLocation
import Foundation

/// 位置のない写真を地図で指定するとき、最初に地図を寄せる場所を、撮影時刻が前後する写真から求める。
enum PhotoLocationGuess {
    struct Point {
        var date: Date
        var coordinate: CLLocationCoordinate2D
    }

    /// 直前と直後の写真の中間点。片側しかなければその位置。1枚もなければ nil。
    static func center(for date: Date, among points: [Point]) -> CLLocationCoordinate2D? {
        let before = points.filter { $0.date <= date }.max { $0.date < $1.date }
        let after = points.filter { $0.date > date }.min { $0.date < $1.date }
        switch (before, after) {
        case let (b?, a?):
            return CLLocationCoordinate2D(
                latitude: (b.coordinate.latitude + a.coordinate.latitude) / 2,
                longitude: (b.coordinate.longitude + a.coordinate.longitude) / 2
            )
        case let (b?, nil): return b.coordinate
        case let (nil, a?): return a.coordinate
        case (nil, nil): return nil
        }
    }
}
