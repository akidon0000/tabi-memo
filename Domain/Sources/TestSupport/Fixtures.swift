import Domain
import Foundation

/// テストで使う写真とトリップを作る。日時は 1970 年からの分で指定する。
public enum Fixtures {
    public static func date(minutes: Double) -> Date {
        Date(timeIntervalSince1970: minutes * 60)
    }

    public static func photo(_ title: String, minutes: Double, removedAt: Date? = nil) -> Photo {
        Photo(
            imageData: Data(),
            coordinate: Coordinate(latitude: 35, longitude: 139),
            takenAt: date(minutes: minutes),
            title: title,
            removedAt: removedAt
        )
    }

    public static func newPhoto(_ title: String, minutes: Double) -> NewPhoto {
        NewPhoto(
            imageData: Data(),
            coordinate: Coordinate(latitude: 35, longitude: 139),
            takenAt: date(minutes: minutes),
            isLocationManuallyPlaced: false,
            title: title,
            memo: ""
        )
    }

    public static func trip(photos: [Photo], hasRoute: Bool = true) -> Trip {
        let points = hasRoute
            ? [LocationPoint(coordinate: Coordinate(latitude: 35, longitude: 139), timestamp: date(minutes: 0))]
            : []
        return Trip(name: "test", startedAt: date(minutes: 0), locationPoints: points, photos: photos)
    }
}
