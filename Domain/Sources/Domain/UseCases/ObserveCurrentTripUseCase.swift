import Foundation

/// 地図に出すトリップ(軌跡のある、いちばん新しいもの)を見張る。無ければ nil を流す。
@MainActor
public struct ObserveCurrentTripUseCase {
    private let tripRepository: any TripRepository

    public init(tripRepository: any TripRepository) {
        self.tripRepository = tripRepository
    }

    public func execute() -> AsyncStream<Trip?> {
        tripRepository.observeTrips().map { trips in
            trips.first { !$0.locationPoints.isEmpty }
        }
    }
}
