import Foundation

/// 写真を撮影順に結ぶ線。区間ごとに、道に沿った経路が分かっていればそれを使い、分からない区間は直線にする。
public enum PhotoPath {
    /// 経路を求める区間。撮影順に隣り合う写真の組。同じ位置の組は線にならないので含めない。
    public static func segments(of photos: [Photo]) -> [RouteSegment] {
        zip(photos, photos.dropFirst())
            .map { RouteSegment(from: $0.coordinate, to: $1.coordinate) }
            .filter { $0.from != $0.to }
    }

    /// 地図に引く座標の並び。`paths` に無い区間は、2点を結ぶ直線。写真が2枚に満たなければ空。
    public static func coordinates(of photos: [Photo], using paths: [RouteSegment: [Coordinate]]) -> [Coordinate] {
        guard photos.count > 1 else { return [] }
        var result = [photos[0].coordinate]
        for (previous, next) in zip(photos, photos.dropFirst()) {
            let segment = RouteSegment(from: previous.coordinate, to: next.coordinate)
            let path = paths[segment] ?? [segment.from, segment.to]
            result.append(contentsOf: path.dropFirst())
        }
        return result
    }
}
