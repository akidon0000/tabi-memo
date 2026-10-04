import Foundation

/// 取り除いた写真を、完全に削除する。元に戻せない。
@MainActor
public struct DeletePhotoPermanentlyUseCase {
    private let photoRepository: any PhotoRepository

    public init(photoRepository: any PhotoRepository) {
        self.photoRepository = photoRepository
    }

    public func execute(photoID: Photo.ID) throws {
        try photoRepository.delete([photoID])
    }
}
