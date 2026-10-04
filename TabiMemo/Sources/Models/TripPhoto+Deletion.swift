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
