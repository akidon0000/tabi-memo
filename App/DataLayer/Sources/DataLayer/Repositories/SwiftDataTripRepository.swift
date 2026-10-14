import Domain
import Foundation
import Observation
import SwiftData

/// SwiftData に保存したトリップを、Domain の `Trip` として流し、作成・名前変更・削除を行う。
/// `ResultsObserver` が保存のたびに結果を更新し、`Observations` がそれを拾って流し直す。
public final class SwiftDataTripRepository: TripRepository {
    /// 保存先を持っておく(ModelContainer を手放さないように)。
    private let store: SwiftDataStore
    private let observer: ResultsObserver<TripRecord, Never>

    public init(store: SwiftDataStore) throws {
        self.store = store
        observer = try ResultsObserver(
            sortBy: [SortDescriptor(\TripRecord.startedAt, order: .reverse)],
            modelContext: store.context
        )
    }

    public func observeTrips() -> AsyncStream<[Trip]> {
        // 変換をこのクロージャの中で行うので、写真や軌跡の中身が変わったときも流れ直す。
        let observations = Observations { self.currentTrips() }
        return AsyncStream { continuation in
            let task = Task {
                for await trips in observations {
                    continuation.yield(trips)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    public func add(_ trip: Trip) throws {
        store.context.insert(TripRecord(id: trip.id, name: trip.name, startedAt: trip.startedAt))
        try store.context.save()
    }

    public func rename(_ tripID: Trip.ID, to name: String) throws {
        for record in try records([tripID]) { record.name = name }
        try store.context.save()
    }

    public func setRemovedAt(_ date: Date?, for tripID: Trip.ID) throws {
        for record in try records([tripID]) { record.removedAt = date }
        try store.context.save()
    }

    public func delete(_ tripIDs: [Trip.ID]) throws {
        for record in try records(tripIDs) { store.context.delete(record) }
        try store.context.save()
    }

    private func records(_ ids: [Trip.ID]) throws -> [TripRecord] {
        try store.context.fetch(FetchDescriptor<TripRecord>(predicate: #Predicate { ids.contains($0.id) }))
    }

    private func currentTrips() -> [Trip] {
        // `observer.results` は、保存を知らせてもらうために読むだけ(中身は読まない)。消したトリップは結果に残っていて、
        // 中身を読むと落ちるので、トリップは保存先から読み直す。
        _ = observer.results
        let descriptor = FetchDescriptor<TripRecord>(sortBy: [SortDescriptor(\TripRecord.startedAt, order: .reverse)])
        return ((try? store.context.fetch(descriptor)) ?? []).map { $0.toDomain() }
    }
}
