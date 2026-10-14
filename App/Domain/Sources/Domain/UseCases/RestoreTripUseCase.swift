import Foundation

/// 削除したトリップを一覧に戻す。
@MainActor
public struct RestoreTripUseCase {
    private let tripRepository: any TripRepository

    public init(tripRepository: any TripRepository) {
        self.tripRepository = tripRepository
    }

    public func execute(tripID: Trip.ID) throws {
        try tripRepository.setRemovedAt(nil, for: tripID)
    }
}
