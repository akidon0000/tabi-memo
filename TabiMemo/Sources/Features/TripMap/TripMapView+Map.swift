import Domain
import MapKit
import SwiftUI

extension TripMapView {
    func map(_ trip: Trip) -> some View {
        Map(position: $cameraPosition) {
            if trip.locationPoints.count > 1 {
                MapPolyline(coordinates: trip.route.map(\.clLocationCoordinate))
                    .stroke(Color.accentColor, lineWidth: 3)
            }
            ForEach(trip.activePhotos) { photo in
                Annotation(
                    photo.takenAt.formatted(date: .omitted, time: .shortened),
                    coordinate: photo.coordinate.clLocationCoordinate,
                    anchor: .bottom
                ) {
                    PhotoPinCallout(photo: photo) {
                        viewModel.select(photo)
                    }
                }
            }
        }
        .mapStyle(.hybrid())
        .onMapCameraChange(frequency: .onEnd) { visibleRegion = $0.region }
    }

    /// 地図をその写真のスポットへ動かす(パネルに隠れない位置へ)。拡大率は変えない。
    func focusMap(on photo: Photo) {
        let span = visibleRegion?.span ?? MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        withAnimation(.easeInOut(duration: 0.8)) {
            // スポットが画面の上から1/4の高さに来るよう、中心を表示範囲の1/4だけ南へずらす(下のパネルに隠れない)。
            let center = CLLocationCoordinate2D(
                latitude: photo.coordinate.latitude - span.latitudeDelta * 0.25,
                longitude: photo.coordinate.longitude
            )
            cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
        }
    }

    /// 写真を選んで、地図をその場所へ動かす(一覧から開いたときなど)。
    func open(_ photo: Photo) {
        viewModel.select(photo)
        focusMap(on: photo)
    }

    /// 新しく追加する写真の位置の初期値が決められないときに使う、地図の中心。
    func fallbackCenter(for trip: Trip) -> Coordinate {
        visibleRegion.map { Coordinate($0.center) }
            ?? trip.activePhotos.first?.coordinate
            ?? Coordinate(latitude: 35.6812, longitude: 139.7671)
    }
}
