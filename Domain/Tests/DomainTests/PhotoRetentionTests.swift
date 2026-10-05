import Domain
import Foundation
import Testing

struct PhotoRetentionTests {
    private let day: TimeInterval = 86_400

    @Test func expiresAfterSevenDays() {
        let removed = Date(timeIntervalSince1970: 1_000_000)
        #expect(!PhotoRetention.isExpired(removed, now: removed.addingTimeInterval(day * 6.9)))
        #expect(PhotoRetention.isExpired(removed, now: removed.addingTimeInterval(day * 7.1)))
    }

    @Test func daysRemainingRoundsUp() {
        let removed = Date(timeIntervalSince1970: 1_000_000)
        #expect(PhotoRetention.daysRemaining(removed, now: removed) == 7)
        #expect(PhotoRetention.daysRemaining(removed, now: removed.addingTimeInterval(day * 6.5)) == 1)
        #expect(PhotoRetention.daysRemaining(removed, now: removed.addingTimeInterval(day * 9)) == 0)
    }
}
