import Foundation

/// 写真と写真の間の1区間。道に沿った経路を、区間ごとに求めて覚えるときのキー。
public struct RouteSegment: Hashable, Sendable {
    public var from: Coordinate
    public var to: Coordinate

    public init(from: Coordinate, to: Coordinate) {
        self.from = from
        self.to = to
    }
}
