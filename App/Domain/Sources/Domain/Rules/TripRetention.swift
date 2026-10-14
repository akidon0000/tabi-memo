import Foundation

/// 削除したトリップを「最近削除したトリップ」に残しておく期間。写真と同じ。
public enum TripRetention {
    public static var days: Int { PhotoRetention.days }

    public static func isExpired(_ removedAt: Date, now: Date = .now) -> Bool {
        PhotoRetention.isExpired(removedAt, now: now)
    }

    /// 完全に消えるまでの残り日数(切り上げ。0 以上)。
    public static func daysRemaining(_ removedAt: Date, now: Date = .now) -> Int {
        PhotoRetention.daysRemaining(removedAt, now: now)
    }
}
