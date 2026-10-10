import Domain
import Foundation
import Observation

/// 写真の編集画面の状態。入力中の値を持ち、保存するまで写真は書き換えない。
@MainActor
@Observable
public final class EditPhotoViewModel {
    let photo: Photo
    var edit: PhotoEdit

    private let updatePhoto: UpdatePhotoUseCase

    public init(photo: Photo, updatePhoto: UpdatePhotoUseCase) {
        self.photo = photo
        edit = PhotoEdit(photo)
        self.updatePhoto = updatePhoto
    }

    /// 地図で場所を指定し直したとき。
    func setLocation(_ coordinate: Coordinate) {
        edit.coordinate = coordinate
        edit.isLocationManuallyPlaced = true
    }

    func save() {
        try? updatePhoto.execute(photoID: photo.id, edit: edit)
    }
}
