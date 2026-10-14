import Domain
import Foundation

/// テスト用の LocationProviding。決めた現在地(または nil)を返す。
@MainActor
public final class FakeLocationProvider: LocationProviding {
    public var location: Coordinate?

    public init(location: Coordinate? = nil) {
        self.location = location
    }

    public func currentLocation() async -> Coordinate? { location }
}
