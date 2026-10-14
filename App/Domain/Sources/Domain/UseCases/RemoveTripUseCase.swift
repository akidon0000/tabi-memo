import Foundation

/// トリップを一覧から外し、「最近削除したトリップ」へ移す。保持期間のあいだは元に戻せる。
@MainActor
public struct RemoveTripUseCase {
    private let tripRepository: any TripRepository

    public init(tripRepository: any TripRepository) {
        self.tripRepository = tripRepository
    }

    public func execute(tripID: Trip.ID, now: Date = .now) throws {
        try tripRepository.setRemovedAt(now, for: tripID)
    }
}
