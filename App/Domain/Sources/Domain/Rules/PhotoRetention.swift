import Foundation

/// 取り除いた写真を「最近取り除いた項目」に残しておく期間。
public enum PhotoRetention {
    public static let days = 7

    public static func expiry(of removedAt: Date, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: days, to: removedAt) ?? removedAt
    }

    public static func isExpired(_ removedAt: Date, now: Date = .now) -> Bool {
        now >= expiry(of: removedAt)
    }

    /// 完全に消えるまでの残り日数(切り上げ。0 以上)。
    public static func daysRemaining(_ removedAt: Date, now: Date = .now) -> Int {
        let seconds = expiry(of: removedAt).timeIntervalSince(now)
        return max(Int((seconds / 86_400).rounded(.up)), 0)
    }
}
