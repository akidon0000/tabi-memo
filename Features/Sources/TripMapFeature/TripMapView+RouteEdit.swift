import Domain
import MapKit
import SharedUI
import SwiftUI

/// 経路編集モード。写真を結ぶ白い破線を長押ししてドラッグすると、ドラッグ先を通る点(経由点)が足され、前後が道なりに引き直される。
/// 経由点は長押しでドラッグして動かし、目印をタップして消す。
extension TripMapView {
    /// 指でなぞっている最中の状態。何を掴んだかと、いまの指の位置(地図の座標系)。
    struct RouteDrag {
        let target: RouteHitTest.Target
        var location: CGPoint
    }

    /// 地図に出す経由点の目印。
    struct WaypointMarker: Identifiable {
        let pair: Int
        let index: Int
        let coordinate: Coordinate
        var id: String { "\(pair)-\(index)" }
    }

    func waypointMarkers(_ trip: Trip) -> [WaypointMarker] {
        viewModel.route.pairs(of: trip).enumerated().flatMap { pairIndex, pair in
            pair.waypoints.enumerated().map { WaypointMarker(pair: pairIndex, index: $0, coordinate: $1) }
        }
        .filter { marker in
            // 動かしている最中の点は、指の位置に出すので、元の場所には出さない。
            routeDrag?.target != .waypoint(pair: marker.pair, index: marker.index)
        }
    }

    /// 経路編集モードの、地図の上のジェスチャー。長押しのあとのドラッグで、経由点を足す・動かす。
    func routeEditGesture(_ proxy: MapProxy, trip: Trip) -> some Gesture {
        LongPressGesture(minimumDuration: 0.4)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onChanged { value in
                guard case .second(true, let drag?) = value else { return }
                if routeDrag == nil {
                    // 最初のイベントは、動き出したあとの位置で届くことがある。押した位置を先に、次に届いた位置で、何を掴んだか判定する。
                    beginRouteDrag(grabbedAt: [drag.startLocation, drag.location], at: drag.location, proxy: proxy, trip: trip)
                } else {
                    routeDrag?.location = drag.location
                }
            }
            .onEnded { value in
                defer { routeDrag = nil }
                guard case .second(true, let drag?) = value, let routeDrag,
                      let coordinate = proxy.convert(drag.location, from: .local) else { return }
                finishRouteDrag(routeDrag.target, at: Coordinate(coordinate), trip: trip)
            }
    }

    /// 経由点を消す(経由点の目印をタップしたとき)。自動の経路に戻る。
    func removeWaypoint(_ marker: WaypointMarker, in trip: Trip) {
        let pairs = viewModel.route.pairs(of: trip)
        viewModel.route.removeWaypoint(at: marker.index, pair: pairs[marker.pair], in: trip)
    }

    /// なぞっている最中の目印(指の位置に出す白い丸)。
    @ViewBuilder
    var routeDragMarker: some View {
        if let routeDrag {
            waypointDot.position(routeDrag.location).allowsHitTesting(false)
        }
    }

    var waypointDot: some View {
        Circle()
            .fill(.white)
            .frame(width: 20, height: 20)
            .overlay(Circle().stroke(Color.blue, lineWidth: 4))
            .shadow(radius: 2)
    }

    /// 上部の「経路を編集中」の帯と「完了」。
    var routeEditBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("経路を編集中").font(.headline)
                    Text("線を長押ししてドラッグ。点はタップで消す").font(.caption)
                }
                Spacer()
                Button("完了") { viewModel.route.finishEditing() }
                    .buttonStyle(.borderedProminent)
            }
            HStack(spacing: 12) {
                Button { viewModel.route.undo() } label: {
                    Label("1つ戻す", systemImage: "arrow.uturn.backward").frame(maxWidth: .infinity)
                }
                Button { viewModel.route.undoAll() } label: {
                    Label("すべて戻す", systemImage: "arrow.counterclockwise").frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.bordered)
            .disabled(!viewModel.route.canUndo)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func beginRouteDrag(grabbedAt grabPoints: [CGPoint], at location: CGPoint, proxy: MapProxy, trip: Trip) {
        let pairs = viewModel.route.pairs(of: trip)
        let legs = pairs.enumerated().flatMap { pairIndex, pair in
            pair.legPaths(using: viewModel.route.legPaths).enumerated().map { legIndex, path in
                RouteHitTest.Leg(pair: pairIndex, leg: legIndex, points: path.compactMap { screenPoint($0, proxy) })
            }
        }
        let handles = screenHandles(proxy: proxy, trip: trip)
        guard let target = grabPoints.lazy.compactMap({ RouteHitTest.target(at: $0, handles: handles, legs: legs) }).first else { return }
        routeDrag = RouteDrag(target: target, location: location)
    }

    private func finishRouteDrag(_ target: RouteHitTest.Target, at coordinate: Coordinate, trip: Trip) {
        let pairs = viewModel.route.pairs(of: trip)
        switch target {
        case let .waypoint(pairIndex, index):
            viewModel.route.moveWaypoint(at: index, to: coordinate, pair: pairs[pairIndex], in: trip)
        case let .leg(pairIndex, leg):
            viewModel.route.insertWaypoint(coordinate, pair: pairs[pairIndex], leg: leg, in: trip)
        }
    }

    private func screenHandles(proxy: MapProxy, trip: Trip) -> [RouteHitTest.Handle] {
        waypointMarkers(trip).compactMap { marker in
            screenPoint(marker.coordinate, proxy).map { RouteHitTest.Handle(pair: marker.pair, index: marker.index, point: $0) }
        }
    }

    private func screenPoint(_ coordinate: Coordinate, _ proxy: MapProxy) -> CGPoint? {
        proxy.convert(coordinate.clLocationCoordinate, to: .local)
    }
}
