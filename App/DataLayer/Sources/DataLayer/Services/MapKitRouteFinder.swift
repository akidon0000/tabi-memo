import CoreLocation
import Domain
import MapKit

/// MapKit の経路検索(MKDirections)で、道に沿った経路を求める。徒歩で求め、無ければ車で求める。
/// 電車・飛行機の区間や、圏外のときは nil を返す(線は直線になる)。
public struct MapKitRouteFinder: RouteFinding {
    public init() {}

    public func route(from: Coordinate, to: Coordinate) async -> [Coordinate]? {
        for transport in [MKDirectionsTransportType.walking, .automobile] {
            if let path = await route(from: from, to: to, transport: transport) { return path }
        }
        return nil
    }

    private func route(from: Coordinate, to: Coordinate, transport: MKDirectionsTransportType) async -> [Coordinate]? {
        let request = MKDirections.Request()
        request.source = MKMapItem(location: CLLocation(latitude: from.latitude, longitude: from.longitude), address: nil)
        request.destination = MKMapItem(location: CLLocation(latitude: to.latitude, longitude: to.longitude), address: nil)
        request.transportType = transport
        guard let route = try? await MKDirections(request: request).calculate().routes.first else { return nil }
        let polyline = route.polyline
        var points = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(), count: polyline.pointCount)
        polyline.getCoordinates(&points, range: NSRange(location: 0, length: polyline.pointCount))
        return points.map { Coordinate(latitude: $0.latitude, longitude: $0.longitude) }
    }
}
