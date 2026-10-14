import Foundation

/// 端末の現在地を求める。許可が無い・求められないときは nil。
@MainActor
public protocol LocationProviding {
    func currentLocation() async -> Coordinate?
}
