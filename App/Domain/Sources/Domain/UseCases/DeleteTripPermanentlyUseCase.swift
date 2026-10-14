import Foundation

/// トリップを完全に消す。写真と線もすべて消え、元に戻せない。
@MainActor
public struct DeleteTripPermanentlyUseCase {
    private let tripRepository: any TripRepository

    public init(tripRepository: any TripRepository) {
        self.tripRepository = tripRepository
    }

    public func execute(tripID: Trip.ID) throws {
        try tripRepository.delete([tripID])
    }
}
