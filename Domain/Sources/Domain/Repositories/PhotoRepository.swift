import Foundation

/// 写真の書き込み。変わった内容は `TripRepository.observeTrips()` から流れてくる。
@MainActor
public protocol PhotoRepository {
    func add(_ photos: [NewPhoto], to tripID: Trip.ID) throws
    func update(_ photoID: Photo.ID, with edit: PhotoEdit) throws
    func setTakenAt(_ dates: [Photo.ID: Date]) throws
    /// nil を渡すと、取り除いた写真を元に戻す。
    func setRemovedAt(_ date: Date?, for photoID: Photo.ID) throws
    /// 完全に消す。元に戻せない。
    func delete(_ photoIDs: [Photo.ID]) throws
}
