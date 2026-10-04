import Foundation

/// 写真の並び順。写真は撮影日時の順に並ぶので、並べ替えは「いまの日時を古い順に並べ直し、新しい並びの順に割り当てる」ことで表す。
public enum PhotoOrdering {
    public struct Item: Hashable, Sendable {
        public var id: UUID
        public var takenAt: Date

        public init(id: UUID, takenAt: Date) {
            self.id = id
            self.takenAt = takenAt
        }
    }

    /// 並び `order` の順に、日時を古い順に割り当てる。日時の集合そのものは変わらない。
    public static func assignDates(to order: [Item]) -> [UUID: Date] {
        let dates = order.map(\.takenAt).sorted()
        return Dictionary(uniqueKeysWithValues: zip(order.map(\.id), dates))
    }

    /// `id` を `target` の位置へ移した並び(グリッドのドラッグ用)。どちらかが無ければそのまま返す。
    public static func moving(_ id: UUID, to target: UUID, in order: [UUID]) -> [UUID] {
        var order = order
        guard let from = order.firstIndex(of: id), let to = order.firstIndex(of: target), from != to else { return order }
        order.insert(order.remove(at: from), at: to)
        return order
    }
}
