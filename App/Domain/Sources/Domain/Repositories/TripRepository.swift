import Foundation

/// トリップの読み出し。保存された内容が変わるたびに、最新の一覧を流す。
@MainActor
public protocol TripRepository {
    /// すべてのトリップ。新しく始めたものが先頭。保存のたびに流れ直すので、呼び出し側で読み直さない。
    func observeTrips() -> AsyncStream<[Trip]>
}
