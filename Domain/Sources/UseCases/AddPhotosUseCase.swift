import Foundation

/// 新しい写真をまとめて保存する。並べ替え画面で決めた並び(すでにある写真を含む)の順に、日時を割り当て直す。
@MainActor
public struct AddPhotosUseCase {
    private let photoRepository: any PhotoRepository

    public init(photoRepository: any PhotoRepository) {
        self.photoRepository = photoRepository
    }

    /// - Parameters:
    ///   - order: すでにある写真と新しい写真の ID を、並べたい順に並べたもの。並べ替えないときは空でよい。
    public func execute(_ newPhotos: [NewPhoto], order: [UUID], to trip: Trip) throws {
        let dates = PhotoOrdering.assignDates(to: orderItems(order, newPhotos: newPhotos, trip: trip))
        let newIDs = Set(newPhotos.map(\.id))
        let existingDates = dates.filter { !newIDs.contains($0.key) }
        if !existingDates.isEmpty {
            try photoRepository.setTakenAt(existingDates)
        }
        let dated = newPhotos.map { photo in
            var photo = photo
            photo.takenAt = dates[photo.id] ?? photo.takenAt
            return photo
        }
        try photoRepository.add(dated, to: trip.id)
    }

    private func orderItems(_ order: [UUID], newPhotos: [NewPhoto], trip: Trip) -> [PhotoOrdering.Item] {
        var dates: [UUID: Date] = [:]
        for photo in trip.activePhotos { dates[photo.id] = photo.takenAt }
        for photo in newPhotos { dates[photo.id] = photo.takenAt }
        return order.compactMap { id in dates[id].map { PhotoOrdering.Item(id: id, takenAt: $0) } }
    }
}
