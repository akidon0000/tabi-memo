import Domain
import Foundation

/// テスト用の TripRepository。`send(_:)` で流したい一覧を流し、書き込みの呼び出しを記録する。
@MainActor
public final class FakeTripRepository: TripRepository {
    private var continuations: [AsyncStream<[Trip]>.Continuation] = []
    public private(set) var latest: [Trip]
    public private(set) var added: [Trip] = []
    public private(set) var renamed: [(tripID: Trip.ID, name: String)] = []
    public private(set) var removedAtChanges: [(date: Date?, tripID: Trip.ID)] = []
    public private(set) var deleted: [[Trip.ID]] = []

    public init(trips: [Trip] = []) {
        latest = trips
    }

    public func observeTrips() -> AsyncStream<[Trip]> {
        let (stream, continuation) = AsyncStream<[Trip]>.makeStream()
        continuation.yield(latest)
        continuations.append(continuation)
        return stream
    }

    public func send(_ trips: [Trip]) {
        latest = trips
        for continuation in continuations { continuation.yield(trips) }
    }

    public func add(_ trip: Trip) throws {
        added.append(trip)
    }

    public func rename(_ tripID: Trip.ID, to name: String) throws {
        renamed.append((tripID, name))
    }

    public func setRemovedAt(_ date: Date?, for tripID: Trip.ID) throws {
        removedAtChanges.append((date, tripID))
    }

    public func delete(_ tripIDs: [Trip.ID]) throws {
        deleted.append(tripIDs)
    }
}
