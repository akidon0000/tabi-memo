import Domain
import Foundation
import SwiftData

/// 写真を結ぶ線の直しの書き込み。最後に保存まで行う。
public final class SwiftDataRouteEditRepository: RouteEditRepository {
    /// 保存先を持っておく(ModelContainer を手放さないように)。
    private let store: SwiftDataStore
    private var context: ModelContext { store.context }

    public init(store: SwiftDataStore) {
        self.store = store
    }

    public func setWaypoints(_ waypoints: [Coordinate], from fromPhotoID: Photo.ID, to toPhotoID: Photo.ID, in tripID: Trip.ID) throws {
        let descriptor = FetchDescriptor<TripRecord>(predicate: #Predicate { $0.id == tripID })
        guard let trip = try context.fetch(descriptor).first else { throw SwiftDataStoreError.tripNotFound(tripID) }
        let existing = trip.routeEdits.first { $0.fromPhotoID == fromPhotoID && $0.toPhotoID == toPhotoID }

        if waypoints.isEmpty {
            if let existing { context.delete(existing) }
        } else if let existing {
            existing.latitudes = waypoints.map(\.latitude)
            existing.longitudes = waypoints.map(\.longitude)
        } else {
            let record = RouteEditRecord(
                fromPhotoID: fromPhotoID,
                toPhotoID: toPhotoID,
                latitudes: waypoints.map(\.latitude),
                longitudes: waypoints.map(\.longitude)
            )
            context.insert(record)
            record.trip = trip
        }
        try context.save()
    }
}
