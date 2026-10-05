import Domain
import Foundation
import Testing
import TestSupport

struct PhotoOrderingTests {
    private let a = UUID(), b = UUID(), c = UUID()

    @Test func assignsSortedDatesInTheGivenOrder() {
        let items = [
            PhotoOrdering.Item(id: c, takenAt: Fixtures.date(minutes: 3)),
            PhotoOrdering.Item(id: a, takenAt: Fixtures.date(minutes: 1)),
            PhotoOrdering.Item(id: b, takenAt: Fixtures.date(minutes: 2)),
        ]
        let dates = PhotoOrdering.assignDates(to: items)
        #expect(dates[c] == Fixtures.date(minutes: 1))
        #expect(dates[a] == Fixtures.date(minutes: 2))
        #expect(dates[b] == Fixtures.date(minutes: 3))
    }

    @Test func movingPutsTheItemAtTheTargetPosition() {
        #expect(PhotoOrdering.moving(a, to: c, in: [a, b, c]) == [b, c, a])
        #expect(PhotoOrdering.moving(c, to: a, in: [a, b, c]) == [c, a, b])
    }

    @Test func movingUnknownIDKeepsTheOrder() {
        #expect(PhotoOrdering.moving(UUID(), to: a, in: [a, b]) == [a, b])
    }
}
