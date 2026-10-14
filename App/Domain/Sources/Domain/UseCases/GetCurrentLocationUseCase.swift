import Foundation

/// 端末の現在地を求める。撮影した写真の位置と、空のトリップの地図の中心に使う。
@MainActor
public struct GetCurrentLocationUseCase {
    private let provider: any LocationProviding

    public init(provider: any LocationProviding) {
        self.provider = provider
    }

    public func execute() async -> Coordinate? {
        await provider.currentLocation()
    }
}
