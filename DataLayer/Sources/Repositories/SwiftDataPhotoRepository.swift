import Domain
import Foundation
import SwiftData

/// 写真の書き込み。どの操作も、最後に保存まで行う。
public final class SwiftDataPhotoRepository: PhotoRepository {
    private let context: ModelContext

    public init(store: SwiftDataStore) {
        context = store.context
    }

    public func add(_ photos: [NewPhoto], to tripID: Trip.ID) throws {
        let descriptor = FetchDescriptor<TripRecord>(predicate: #Predicate { $0.id == tripID })
        guard let trip = try context.fetch(descriptor).first else { throw SwiftDataStoreError.tripNotFound(tripID) }
        for photo in photos {
            let record = PhotoRecord(photo)
            context.insert(record)
            record.trip = trip
        }
        try context.save()
    }

    public func update(_ photoID: Photo.ID, with edit: PhotoEdit) throws {
        for record in try records([photoID]) { record.apply(edit) }
        try context.save()
    }

    public func setTakenAt(_ dates: [Photo.ID: Date]) throws {
        for record in try records(Array(dates.keys)) {
            if let date = dates[record.id] { record.takenAt = date }
        }
        try context.save()
    }

    public func setRemovedAt(_ date: Date?, for photoID: Photo.ID) throws {
        for record in try records([photoID]) { record.removedAt = date }
        try context.save()
    }

    public func delete(_ photoIDs: [Photo.ID]) throws {
        for record in try records(photoIDs) { context.delete(record) }
        try context.save()
    }

    private func records(_ ids: [Photo.ID]) throws -> [PhotoRecord] {
        try context.fetch(FetchDescriptor<PhotoRecord>(predicate: #Predicate { ids.contains($0.id) }))
    }
}
