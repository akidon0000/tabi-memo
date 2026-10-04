import Foundation
import SwiftData

/// 削除した写真を「最近削除した項目」に残しておく期間。
nonisolated enum PhotoRetention {
    static let days = 7

    static func expiry(of deletedAt: Date, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: days, to: deletedAt) ?? deletedAt
    }

    static func isExpired(_ deletedAt: Date, now: Date = .now) -> Bool {
        now >= expiry(of: deletedAt)
    }

    /// 完全に消えるまでの残り日数(切り上げ。0 以上)。
    static func daysRemaining(_ deletedAt: Date, now: Date = .now) -> Int {
        let seconds = expiry(of: deletedAt).timeIntervalSince(now)
        return max(Int((seconds / 86_400).rounded(.up)), 0)
    }
}

extension Trip {
    /// 地図・並べ替え・隣の写真への移動に使う写真(削除したものを除く)。
    var activePhotos: [TripPhoto] { photos.filter { $0.deletedAt == nil } }

    /// 「最近削除した項目」に出す写真。新しく消したものが先頭。
    var deletedPhotos: [TripPhoto] {
        photos.filter { $0.deletedAt != nil }.sorted { ($0.deletedAt ?? .distantPast) > ($1.deletedAt ?? .distantPast) }
    }

    /// 保持期間を過ぎた写真を完全に消す。アプリを開いたときと、一覧を開いたときに呼ぶ。
    func purgeExpiredPhotos(in context: ModelContext, now: Date = .now) {
        for photo in photos {
            if let deletedAt = photo.deletedAt, PhotoRetention.isExpired(deletedAt, now: now) {
                context.delete(photo)
            }
        }
        try? context.save()
    }
}

extension Trip {
    /// 地図に出ている写真を、撮影日時の順に並べたもの。
    var sortedActivePhotos: [TripPhoto] { activePhotos.sorted { $0.takenAt < $1.takenAt } }

    /// 写真は日時の順で並ぶので、並べ替えは「いまの日時を古い順に並べ直し、新しい並びの順に割り当てる」ことで表す。
    func applyOrder(_ order: [TripPhoto]) {
        let dates = order.map(\.takenAt).sorted()
        for (photo, date) in zip(order, dates) { photo.takenAt = date }
    }

    /// `photo` を `target` の位置へ移す(グリッドのドラッグ用)。
    func move(_ photo: TripPhoto, to target: TripPhoto) {
        var order = sortedActivePhotos
        guard let from = order.firstIndex(where: { $0.id == photo.id }),
              let to = order.firstIndex(where: { $0.id == target.id }), from != to else { return }
        order.insert(order.remove(at: from), at: to)
        applyOrder(order)
    }
}
