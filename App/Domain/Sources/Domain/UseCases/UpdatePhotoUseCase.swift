import Foundation

/// 編集画面の内容で、写真を書き換える。
@MainActor
public struct UpdatePhotoUseCase {
    private let photoRepository: any PhotoRepository

    public init(photoRepository: any PhotoRepository) {
        self.photoRepository = photoRepository
    }

    public func execute(photoID: Photo.ID, edit: PhotoEdit) throws {
        try photoRepository.update(photoID, with: edit)
    }
}
