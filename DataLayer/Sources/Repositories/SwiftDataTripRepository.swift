import Domain
import Foundation
import Observation
import SwiftData

/// SwiftData に保存したトリップを、Domain の `Trip` として流す。
/// `ResultsObserver` が保存のたびに結果を更新し、`Observations` がそれを拾って流し直す。
public final class SwiftDataTripRepository: TripRepository {
    private let observer: ResultsObserver<TripRecord, Never>

    public init(store: SwiftDataStore) throws {
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

    private func currentTrips() -> [Trip] {
        observer.results.map { $0.toDomain() }
    }
}
