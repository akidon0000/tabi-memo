import Foundation

/// 取り除いた写真を、地図に戻す。
@MainActor
public struct RestorePhotoUseCase {
    private let photoRepository: any PhotoRepository

    public init(photoRepository: any PhotoRepository) {
        self.photoRepository = photoRepository
    }

    public func execute(photoID: Photo.ID) throws {
        try photoRepository.setRemovedAt(nil, for: photoID)
    }
}
