import Foundation

/// 折れ線(経路)に沿って動くときの、距離から位置・向きを求める計算。単位はメートル。
public struct PathPlayback: Sendable {
    public struct Sample: Equatable, Sendable {
        public var coordinate: Coordinate
        /// 進行方向(度。北が 0、東が 90)。
        public var heading: Double

        public init(coordinate: Coordinate, heading: Double) {
            self.coordinate = coordinate
            self.heading = heading
        }
    }

    private let points: [Coordinate]
    /// 各点までの、始点からの道のり。
    private let cumulative: [Double]

    public init(path: [Coordinate]) {
        points = path
        var total = 0.0
        cumulative = path.indices.map { index in
            if index > 0 { total += Self.meters(from: path[index - 1], to: path[index]) }
            return total
        }
    }

    /// 経路の全長。
    public var length: Double { cumulative.last ?? 0 }

    /// 始点から `distance` 進んだ位置。範囲の外は両端に丸める。点が1つに満たなければ nil。
    public func sample(atDistance distance: Double) -> Sample? {
        guard let first = points.first else { return nil }
        guard points.count > 1 else { return Sample(coordinate: first, heading: 0) }
        let clamped = min(max(distance, 0), length)
        let end = cumulative.firstIndex { $0 >= clamped && $0 > 0 } ?? points.count - 1
        let start = max(end - 1, 0)
        let segment = cumulative[end] - cumulative[start]
        let fraction = segment > 0 ? (clamped - cumulative[start]) / segment : 0
        let a = points[start]
        let b = points[end]
        return Sample(
            coordinate: Coordinate(
                latitude: a.latitude + (b.latitude - a.latitude) * fraction,
                longitude: a.longitude + (b.longitude - a.longitude) * fraction
            ),
            heading: Self.bearing(from: a, to: b)
        )
    }

    /// 地点(写真など)に最も近い点の、道のり。前の地点より後ろの点だけを探すので、順に通る地点なら、通る順に並ぶ。
    public func distances(near stops: [Coordinate]) -> [Double] {
        var searchFrom = 0
        return stops.map { stop in
            let candidates = points.indices.dropFirst(searchFrom)
            let nearest = candidates.min { Self.meters(from: points[$0], to: stop) < Self.meters(from: points[$1], to: stop) }
            searchFrom = nearest ?? searchFrom
            return nearest.map { cumulative[$0] } ?? 0
        }
    }

    /// 2点間の距離(メートル)。ハーバーサイン。
    static func meters(from a: Coordinate, to b: Coordinate) -> Double {
        let radius = 6_371_000.0
        let lat1 = a.latitude * .pi / 180
        let lat2 = b.latitude * .pi / 180
        let dLat = lat2 - lat1
        let dLon = (b.longitude - a.longitude) * .pi / 180
        let h = sin(dLat / 2) * sin(dLat / 2) + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        return 2 * radius * asin(min(1, sqrt(h)))
    }

    /// a から b へ向かう方位(度)。
    static func bearing(from a: Coordinate, to b: Coordinate) -> Double {
        let lat1 = a.latitude * .pi / 180
        let lat2 = b.latitude * .pi / 180
        let dLon = (b.longitude - a.longitude) * .pi / 180
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let degrees = atan2(y, x) * 180 / .pi
        return degrees < 0 ? degrees + 360 : degrees
    }
}
