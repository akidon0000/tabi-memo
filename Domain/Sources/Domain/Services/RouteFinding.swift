import Foundation

/// 2点の間の、道に沿った経路を求める。求められないとき(圏外・道がない・電車や飛行機の区間など)は nil。
@MainActor
public protocol RouteFinding {
    func route(from: Coordinate, to: Coordinate) async -> [Coordinate]?
}
