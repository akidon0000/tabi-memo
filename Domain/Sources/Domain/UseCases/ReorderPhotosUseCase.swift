import Foundation

/// 地図にある写真を並べ替える。新しい並びの順に、いまの日時を古い順に割り当て直す。
@MainActor
public struct ReorderPhotosUseCase {
    private let photoRepository: any PhotoRepository

    public init(photoRepository: any PhotoRepository) {
        self.photoRepository = photoRepository
    }

    /// - Parameter order: `trip.activePhotos` の ID を、並べたい順に並べたもの。
    public func execute(order: [Photo.ID], in trip: Trip) throws {
        let photos = Dictionary(uniqueKeysWithValues: trip.activePhotos.map { ($0.id, $0) })
        let items = order.compactMap { id in photos[id].map { PhotoOrdering.Item(id: id, takenAt: $0.takenAt) } }
        try photoRepository.setTakenAt(PhotoOrdering.assignDates(to: items))
    }
}
