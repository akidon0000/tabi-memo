import Foundation

/// 一覧に出すトリップと、削除したトリップを見張る。
@MainActor
public struct ObserveTripsUseCase {
    private let tripRepository: any TripRepository

    public init(tripRepository: any TripRepository) {
        self.tripRepository = tripRepository
    }

    /// 一覧に出すトリップ(新しい順)と、削除したトリップ(新しく削除したものが先頭)。
    public func execute() -> AsyncStream<(active: [Trip], removed: [Trip])> {
        tripRepository.observeTrips().map { trips in
            (
                active: trips.filter { !$0.isRemoved },
                removed: trips.filter(\.isRemoved).sorted { ($0.removedAt ?? .distantPast) > ($1.removedAt ?? .distantPast) }
            )
        }
    }
}
