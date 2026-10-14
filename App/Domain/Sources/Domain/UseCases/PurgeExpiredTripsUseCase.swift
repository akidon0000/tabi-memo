import Foundation

/// 保持期間を過ぎた、削除したトリップを完全に消す。一覧を開いたときに呼ぶ。
@MainActor
public struct PurgeExpiredTripsUseCase {
    private let tripRepository: any TripRepository

    public init(tripRepository: any TripRepository) {
        self.tripRepository = tripRepository
    }

    public func execute(in trips: [Trip], now: Date = .now) throws {
        let expired = trips.filter { trip in
            trip.removedAt.map { TripRetention.isExpired($0, now: now) } ?? false
        }
        guard !expired.isEmpty else { return }
        try tripRepository.delete(expired.map(\.id))
    }
}
