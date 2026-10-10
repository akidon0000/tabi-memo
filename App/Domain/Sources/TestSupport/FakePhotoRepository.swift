import Domain
import Foundation

/// テスト用の PhotoRepository。呼ばれた内容を記録する。
@MainActor
public final class FakePhotoRepository: PhotoRepository {
    public private(set) var added: [(photos: [NewPhoto], tripID: Trip.ID)] = []
    public private(set) var updated: [(photoID: Photo.ID, edit: PhotoEdit)] = []
    public private(set) var takenAtChanges: [[Photo.ID: Date]] = []
    public private(set) var removedAtChanges: [(date: Date?, photoID: Photo.ID)] = []
    public private(set) var deleted: [[Photo.ID]] = []

    public init() {}

    public func add(_ photos: [NewPhoto], to tripID: Trip.ID) throws {
        added.append((photos, tripID))
    }

    public func update(_ photoID: Photo.ID, with edit: PhotoEdit) throws {
        updated.append((photoID, edit))
    }

    public func setTakenAt(_ dates: [Photo.ID: Date]) throws {
        takenAtChanges.append(dates)
    }

    public func setRemovedAt(_ date: Date?, for photoID: Photo.ID) throws {
        removedAtChanges.append((date, photoID))
    }

    public func delete(_ photoIDs: [Photo.ID]) throws {
        deleted.append(photoIDs)
    }
}
