import CoreLocation
import Domain

// Domain の座標と、地図のフレームワークの座標の変換。App の中だけで使う。

extension Coordinate {
    public init(_ coordinate: CLLocationCoordinate2D) {
        self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    public var clLocationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
