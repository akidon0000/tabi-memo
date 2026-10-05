import Foundation

/// 写真を撮影順に結ぶ線。写真の組ごとに「出発 → 経由点 → … → 到着」の区間に分け、
/// 区間ごとに、道に沿った経路が分かっていればそれを使い、分からない区間は直線にする。
public enum PhotoPath {
    /// 撮影順に隣り合う写真の組と、その間の経由点。
    public struct Pair: Hashable, Sendable {
        public var fromPhotoID: Photo.ID
        public var toPhotoID: Photo.ID
        public var waypoints: [Coordinate]
        /// 出発・経由点・到着の座標。
        public var stops: [Coordinate]

        /// 経路を求める区間。`stops` の隣り合う2点ごと(区間 k は stops[k] → stops[k+1])。
        public var legs: [RouteSegment] {
            zip(stops, stops.dropFirst()).map { RouteSegment(from: $0, to: $1) }
        }

        /// 区間ごとの座標の並び。`paths` に無い区間は、2点を結ぶ直線。
        public func legPaths(using paths: [RouteSegment: [Coordinate]]) -> [[Coordinate]] {
            legs.map { paths[$0] ?? [$0.from, $0.to] }
        }
    }

    public static func pairs(of photos: [Photo], edits: [RouteEdit] = []) -> [Pair] {
        zip(photos, photos.dropFirst()).map { previous, next in
            let waypoints = edits.first { $0.fromPhotoID == previous.id && $0.toPhotoID == next.id }?.waypoints ?? []
            return Pair(
                fromPhotoID: previous.id,
                toPhotoID: next.id,
                waypoints: waypoints,
                stops: [previous.coordinate] + waypoints + [next.coordinate]
            )
        }
    }

    /// 経路を求める区間。同じ位置の2点は線にならないので含めない。
    public static func segments(of photos: [Photo], edits: [RouteEdit] = []) -> [RouteSegment] {
        pairs(of: photos, edits: edits).flatMap(\.legs).filter { $0.from != $0.to }
    }

    /// 地図に引く座標の並び。写真が2枚に満たなければ空。
    public static func coordinates(of photos: [Photo], edits: [RouteEdit] = [], using paths: [RouteSegment: [Coordinate]]) -> [Coordinate] {
        guard let first = photos.first, photos.count > 1 else { return [] }
        var result = [first.coordinate]
        for path in pairs(of: photos, edits: edits).flatMap({ $0.legPaths(using: paths) }) {
            result.append(contentsOf: path.dropFirst())
        }
        return result
    }
}
