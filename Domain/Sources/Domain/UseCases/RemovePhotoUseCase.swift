import Foundation

/// 写真を地図から取り除き、「最近取り除いた項目」へ移す。保持期間のあいだは元に戻せる。
@MainActor
public struct RemovePhotoUseCase {
    private let photoRepository: any PhotoRepository

    public init(photoRepository: any PhotoRepository) {
        self.photoRepository = photoRepository
    }

    public func execute(photoID: Photo.ID, now: Date = .now) throws {
        try photoRepository.setRemovedAt(now, for: photoID)
    }
}
