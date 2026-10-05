import AddPhotosFeature
import Domain
import EditPhotoFeature
import PhotoListFeature
import RecentlyDeletedFeature
import SharedUI
import MapKit
import SwiftUI

extension TripMapView {
    /// 写真ピンの見た目の大きさ(吹き出しの尖りを含む)。重なりの判定に使う。
    private var pinSize: CGSize { CGSize(width: 60, height: 67) }

    func map(_ trip: Trip) -> some View {
        MapReader { proxy in
            mapContent(trip)
                .gesture(longPress(on: proxy), isEnabled: !viewModel.route.isEditing)
                .gesture(routeEditGesture(proxy, trip: trip), isEnabled: viewModel.route.isEditing)
                .overlay { routeDragMarker }
                .sensoryFeedback(.impact, trigger: placement)
        }
    }

    /// 地図の長押し。押した場所を座標にして、その場所に写真を追加する。
    private func longPress(on proxy: MapProxy) -> some Gesture {
        LongPressGesture(minimumDuration: 0.5)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onEnded { value in
                guard case .second(true, let drag?) = value,
                      let coordinate = proxy.convert(drag.location, from: .local) else { return }
                addPhoto(at: Coordinate(coordinate))
            }
    }

    private func mapContent(_ trip: Trip) -> some View {
        // 経路編集モードでは、設定によって地図の移動・拡大を止める(ドラッグが地図の移動と混ざらないように)。
        Map(position: $cameraPosition, interactionModes: mapInteractionModes) {
            // 写真を撮った順に結ぶ青い線。道に沿った経路が求まった区間は道なり、それ以外は直線。
            if viewModel.route.path(of: trip).count > 1 {
                MapPolyline(coordinates: viewModel.route.path(of: trip).map(\.clLocationCoordinate))
                    .stroke(.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
            }
            if let sample = viewModel.playback.sample {
                Annotation("", coordinate: sample.coordinate.clLocationCoordinate, anchor: .center) {
                    playbackMarker(heading: sample.heading)
                }
            }
            if viewModel.route.isEditing {
                ForEach(waypointMarkers(trip)) { marker in
                    Annotation("", coordinate: marker.coordinate.clLocationCoordinate, anchor: .center) {
                        waypointDot
                            .frame(width: 44, height: 44)
                            .contentShape(Circle())
                            .onTapGesture { removeWaypoint(marker, in: trip) }
                    }
                }
            }
            ForEach(clusters(of: trip)) { cluster in
                Annotation(
                    annotationTitle(cluster),
                    coordinate: cluster.coordinate.clLocationCoordinate,
                    anchor: .bottom
                ) {
                    pin(cluster)
                }
            }
        }
        .mapStyle(.hybrid())
        .onMapCameraChange(frequency: .onEnd) { visibleRegion = $0.region }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { mapSize = $0 }
    }

    @ViewBuilder
    private func pin(_ cluster: PhotoClustering.Cluster) -> some View {
        Group {
            if cluster.photos.count == 1 {
                PhotoPinCallout(photo: cluster.photos[0]) {
                    viewModel.select(cluster.photos[0])
                }
            } else {
                PhotoClusterCallout(photos: cluster.photos) {
                    openCluster(cluster)
                }
            }
        }
        // 経路編集モードでは、ピンを押してもパネルを開かない(線を掴む操作と混ざらないように)。
        .allowsHitTesting(!viewModel.route.isEditing)
    }

    private func annotationTitle(_ cluster: PhotoClustering.Cluster) -> String {
        if cluster.photos.count == 1 {
            return cluster.photos[0].takenAt.formatted(date: .omitted, time: .shortened)
        }
        return "\(cluster.photos.count)枚"
    }

    /// いまの縮尺で、ピンが重なる写真をまとめる。縮尺が分かるまではまとめない。
    private func clusters(of trip: Trip) -> [PhotoClustering.Cluster] {
        guard let region = visibleRegion, mapSize.width > 0, mapSize.height > 0 else {
            return PhotoClustering.clusters(of: trip.activePhotos, latitudeThreshold: 0, longitudeThreshold: 0)
        }
        return PhotoClustering.clusters(
            of: trip.activePhotos,
            latitudeThreshold: region.span.latitudeDelta * pinSize.height / mapSize.height,
            longitudeThreshold: region.span.longitudeDelta * pinSize.width / mapSize.width
        )
    }

    /// まとめたピンを押したとき。地図を寄せて分かれて見えるようにする。同じ場所に重なっていて寄せても分かれないなら、最初の写真を開く。
    private func openCluster(_ cluster: PhotoClustering.Cluster) {
        let rect = mapRect(enclosing: cluster.photos.map(\.coordinate))
        let meters = max(rect.width, rect.height) / MKMapPointsPerMeterAtLatitude(cluster.coordinate.latitude)
        guard meters > 20 else {
            open(cluster.photos[0])
            return
        }
        move(toFit: cluster.photos.map(\.coordinate), minimumMeters: 50)
    }

    /// 経路編集の最中(設定が止める側のとき)と、再生の最中は、地図を指で動かせない。
    private var mapInteractionModes: MapInteractionModes {
        (viewModel.route.isEditing && routeEditLocksMap) || viewModel.playback.isPlaying ? [] : .all
    }

    /// 再生中に線の上を動く目印。進行方向を向く。
    private func playbackMarker(heading: Double) -> some View {
        Image(systemName: "location.north.fill")
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(.white)
            .rotationEffect(.degrees(heading))
            .frame(width: 30, height: 30)
            .background(Circle().fill(Color.blue))
            .overlay(Circle().stroke(.white, lineWidth: 3))
            .shadow(radius: 3)
            .allowsHitTesting(false)
    }

    /// 再生を始める・止める。始めるときは、いまの拡大率のまま、目印を追いかける。
    func togglePlayback() {
        if viewModel.playback.isPlaying {
            viewModel.playback.stop()
            return
        }
        guard let trip = viewModel.trip else { return }
        playbackSpan = visibleRegion?.span ?? playbackSpan
        viewModel.playback.start(
            path: viewModel.route.path(of: trip),
            photos: trip.activePhotos
        )
    }

    /// 再生で止まっている写真。
    func featuredPlaybackPhoto(in trip: Trip) -> Photo? {
        guard let id = viewModel.playback.featuredPhotoID else { return nil }
        return trip.activePhotos.first { $0.id == id }
    }

    /// 目印を地図の中心に置く(アニメーションなし。毎フレーム呼ばれる)。
    func followPlayback(_ sample: PathPlayback.Sample) {
        cameraPosition = .region(MKCoordinateRegion(center: sample.coordinate.clLocationCoordinate, span: playbackSpan))
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

    /// 写真がすべて画面に収まるよう、地図を拡大・縮小する(写真を追加した後)。
    func fitAllPhotos(of trip: Trip) {
        move(toFit: trip.activePhotos.map(\.coordinate), minimumMeters: 600)
    }

    /// 座標がすべて収まるように地図を動かす。
    /// 緯度・経度の幅(MKCoordinateRegion)で指定すると、高緯度ほど横に伸びるメルカトル図法とずれて端の写真がはみ出すので、
    /// 地図上の平面座標(MKMapRect)で囲む。下の追加ボタンやパネルに隠れないよう、下側の余白を広く取る。
    private func move(toFit coordinates: [Coordinate], minimumMeters: Double) {
        guard let first = coordinates.first else { return }
        var rect = mapRect(enclosing: coordinates)
        let minimum = minimumMeters * MKMapPointsPerMeterAtLatitude(first.latitude)
        rect = rect.insetBy(dx: -max(minimum - rect.width, 0) / 2, dy: -max(minimum - rect.height, 0) / 2)
        let padded = MKMapRect(
            x: rect.minX - rect.width * 0.2,
            y: rect.minY - rect.height * 0.25,
            width: rect.width * 1.4,
            height: rect.height * 1.7
        )
        withAnimation(.easeInOut(duration: 0.8)) {
            cameraPosition = .rect(clampedToWorld(padded))
        }
    }

    /// 世界より広い範囲は地図に映せないので、中心を保ったまま世界の大きさに収める(地球の半分を超えて散らばった写真のとき)。
    private func clampedToWorld(_ rect: MKMapRect) -> MKMapRect {
        let world = MKMapRect.world
        let width = min(rect.width, world.width)
        let height = min(rect.height, world.height)
        let y = min(max(rect.midY - height / 2, world.minY), world.maxY - height)
        return MKMapRect(x: rect.midX - width / 2, y: y, width: width, height: height)
    }

    private func mapRect(enclosing coordinates: [Coordinate]) -> MKMapRect {
        coordinates
            .map { MKMapRect(origin: MKMapPoint($0.clLocationCoordinate), size: MKMapSize(width: 0, height: 0)) }
            .reduce(MKMapRect.null) { $0.union($1) }
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
