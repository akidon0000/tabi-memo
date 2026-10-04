import Foundation

/// 保持期間を過ぎた、取り除いた写真を完全に消す。地図を開いたときと、「最近取り除いた項目」を開いたときに呼ぶ。
@MainActor
public struct PurgeExpiredPhotosUseCase {
    private let photoRepository: any PhotoRepository

    public init(photoRepository: any PhotoRepository) {
        self.photoRepository = photoRepository
    }

    public func execute(in trip: Trip, now: Date = .now) throws {
        let expired = trip.removedPhotos.filter { photo in
            photo.removedAt.map { PhotoRetention.isExpired($0, now: now) } ?? false
        }
        guard !expired.isEmpty else { return }
        try photoRepository.delete(expired.map(\.id))
    }
}
