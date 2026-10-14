import Foundation

/// 名前を付けて、空のトリップを作る。名前が空なら「新しいトリップ」にする。
@MainActor
public struct CreateTripUseCase {
    private let tripRepository: any TripRepository

    public init(tripRepository: any TripRepository) {
        self.tripRepository = tripRepository
    }

    @discardableResult
    public func execute(name: String, now: Date = .now) throws -> Trip.ID {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trip = Trip(name: trimmed.isEmpty ? "新しいトリップ" : trimmed, startedAt: now)
        try tripRepository.add(trip)
        return trip.id
    }
}
