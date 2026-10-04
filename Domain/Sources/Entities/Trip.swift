import Foundation

/// 1回の旅。軌跡と写真を持つ。
public struct Trip: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var startedAt: Date
    public var endedAt: Date?
    public var locationPoints: [LocationPoint]
    public var photos: [Photo]

    public init(
        id: UUID = UUID(),
        name: String,
        startedAt: Date,
        endedAt: Date? = nil,
        locationPoints: [LocationPoint] = [],
        photos: [Photo] = []
    ) {
        self.id = id
        self.name = name
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.locationPoints = locationPoints
        self.photos = photos
    }

    /// 地図・一覧・前後の移動に使う写真。取り除いたものを除き、撮影日時の順。
    public var activePhotos: [Photo] {
        photos.filter { !$0.isRemoved }.sorted { $0.takenAt < $1.takenAt }
    }

    /// 「最近取り除いた項目」に出す写真。新しく取り除いたものが先頭。
    public var removedPhotos: [Photo] {
        photos.filter(\.isRemoved).sorted { ($0.removedAt ?? .distantPast) > ($1.removedAt ?? .distantPast) }
    }

    /// 軌跡の線。時刻の順に並べた座標。
    public var route: [Coordinate] {
        locationPoints.sorted { $0.timestamp < $1.timestamp }.map(\.coordinate)
    }

    /// 撮影順で隣の写真(step: 前 -1 / 次 +1)。端なら nil。
    public func neighbor(_ step: Int, of photoID: Photo.ID) -> Photo? {
        let photos = activePhotos
        guard let index = photos.firstIndex(where: { $0.id == photoID }),
              photos.indices.contains(index + step) else { return nil }
        return photos[index + step]
    }
}
