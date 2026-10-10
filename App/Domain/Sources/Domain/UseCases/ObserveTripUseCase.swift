import Foundation

/// 1つのトリップを見張る。消えたら nil を流す。
@MainActor
public struct ObserveTripUseCase {
    private let tripRepository: any TripRepository

    public init(tripRepository: any TripRepository) {
        self.tripRepository = tripRepository
    }

    public func execute(tripID: Trip.ID) -> AsyncStream<Trip?> {
        tripRepository.observeTrips().map { trips in
            trips.first { $0.id == tripID }
        }
    }
}
