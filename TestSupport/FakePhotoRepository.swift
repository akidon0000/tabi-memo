import Domain
import Foundation

/// テスト用の PhotoRepository。呼ばれた内容を記録する。
@MainActor
final class FakePhotoRepository: PhotoRepository {
    private(set) var added: [(photos: [NewPhoto], tripID: Trip.ID)] = []
    private(set) var updated: [(photoID: Photo.ID, edit: PhotoEdit)] = []
    private(set) var takenAtChanges: [[Photo.ID: Date]] = []
    private(set) var removedAtChanges: [(date: Date?, photoID: Photo.ID)] = []
    private(set) var deleted: [[Photo.ID]] = []

    func add(_ photos: [NewPhoto], to tripID: Trip.ID) throws {
        added.append((photos, tripID))
    }

    func update(_ photoID: Photo.ID, with edit: PhotoEdit) throws {
        updated.append((photoID, edit))
    }

    func setTakenAt(_ dates: [Photo.ID: Date]) throws {
        takenAtChanges.append(dates)
    }

    func setRemovedAt(_ date: Date?, for photoID: Photo.ID) throws {
        removedAtChanges.append((date, photoID))
    }

    func delete(_ photoIDs: [Photo.ID]) throws {
        deleted.append(photoIDs)
    }
}
