import Foundation

/// トリップの読み出しと書き込み。変わった内容は `observeTrips()` から流れてくる。
@MainActor
public protocol TripRepository {
    /// すべてのトリップ(削除したものも含む)。新しく始めたものが先頭。保存のたびに流れ直すので、呼び出し側で読み直さない。
    func observeTrips() -> AsyncStream<[Trip]>
    /// 空のトリップを1つ作る。
    func add(_ trip: Trip) throws
    func rename(_ tripID: Trip.ID, to name: String) throws
    /// nil を渡すと、削除したトリップを元に戻す。
    func setRemovedAt(_ date: Date?, for tripID: Trip.ID) throws
    /// 完全に消す。写真と線もすべて消え、元に戻せない。
    func delete(_ tripIDs: [Trip.ID]) throws
}
