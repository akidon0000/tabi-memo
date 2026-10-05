import Domain
import Foundation

/// テスト用の TripRepository。`send(_:)` で流したい一覧を流す。
@MainActor
public final class FakeTripRepository: TripRepository {
    private var continuations: [AsyncStream<[Trip]>.Continuation] = []
    public private(set) var latest: [Trip]

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
}
