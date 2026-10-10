import Foundation

/// 2点の間の道なりの経路を求める。求められなければ、2点を結ぶ直線を返す。
@MainActor
public struct FindRouteUseCase {
    private let finder: any RouteFinding

    public init(finder: any RouteFinding) {
        self.finder = finder
    }

    public func execute(from: Coordinate, to: Coordinate) async -> [Coordinate] {
        if let path = await finder.route(from: from, to: to), path.count >= 2 {
            return path
        }
        return [from, to]
    }
}
