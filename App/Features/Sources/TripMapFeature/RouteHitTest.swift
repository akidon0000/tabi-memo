import CoreGraphics

/// 経路編集モードで、画面の指の位置が、どの経由点・どの区間に当たるかを調べる(画面上の距離で判定する)。
enum RouteHitTest {
    enum Target: Equatable {
        /// 既存の経由点を掴んだ。`pair` は写真の組の番号、`index` はその組の経由点の番号。
        case waypoint(pair: Int, index: Int)
        /// 線の途中を掴んだ。`leg` は区間の番号(新しい経由点は、その区間の前に入る)。
        case leg(pair: Int, leg: Int)
    }

    struct Handle {
        var pair: Int
        var index: Int
        var point: CGPoint
    }

    struct Leg {
        var pair: Int
        var leg: Int
        var points: [CGPoint]
    }

    /// 経由点を先に探し(半径内で最も近いもの)、無ければ、線までの距離が近い区間を返す。
    static func target(
        at point: CGPoint,
        handles: [Handle],
        legs: [Leg],
        handleRadius: CGFloat = 28,
        pathDistance: CGFloat = 30
    ) -> Target? {
        let nearestHandle = handles
            .map { (handle: $0, distance: hypot($0.point.x - point.x, $0.point.y - point.y)) }
            .filter { $0.distance <= handleRadius }
            .min { $0.distance < $1.distance }
        if let nearestHandle { return .waypoint(pair: nearestHandle.handle.pair, index: nearestHandle.handle.index) }

        let nearestLeg = legs
            .map { (leg: $0, distance: distance(from: point, to: $0.points)) }
            .filter { $0.distance <= pathDistance }
            .min { $0.distance < $1.distance }
        return nearestLeg.map { .leg(pair: $0.leg.pair, leg: $0.leg.leg) }
    }

    /// 点から折れ線までの最短距離。
    static func distance(from point: CGPoint, to polyline: [CGPoint]) -> CGFloat {
        guard polyline.count > 1 else { return polyline.first.map { hypot($0.x - point.x, $0.y - point.y) } ?? .infinity }
        return zip(polyline, polyline.dropFirst()).map { distance(from: point, toSegment: $0, $1) }.min() ?? .infinity
    }

    private static func distance(from point: CGPoint, toSegment a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = b.x - a.x
        let dy = b.y - a.y
        let lengthSquared = dx * dx + dy * dy
        guard lengthSquared > 0 else { return hypot(point.x - a.x, point.y - a.y) }
        let t = max(0, min(1, ((point.x - a.x) * dx + (point.y - a.y) * dy) / lengthSquared))
        return hypot(point.x - (a.x + t * dx), point.y - (a.y + t * dy))
    }
}
