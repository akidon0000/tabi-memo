import Foundation

/// トリップの名前を変える。空の名前には変えない。
@MainActor
public struct RenameTripUseCase {
    private let tripRepository: any TripRepository

    public init(tripRepository: any TripRepository) {
        self.tripRepository = tripRepository
    }

    public func execute(tripID: Trip.ID, name: String) throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        try tripRepository.rename(tripID, to: trimmed)
    }
}
