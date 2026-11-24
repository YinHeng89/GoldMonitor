import XCTest
@testable import GoldMonitor

private final class MockNotifier: Notifying, @unchecked Sendable {
    private let lock = NSLock()
    private(set) var titles: [String] = []

    func requestAuthorization() async throws {}

    func send(title: String, body: String) async {
        lock.lock()
        titles.append(title)
        lock.unlock()
    }

    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return titles.count
    }
}

final class AlertLogicTests: XCTestCase {
    private func quote(_ price: Double, kind: GoldQuote.Kind = .icbc, fetchedAt: Date = Date()) -> GoldQuote {
        GoldQuote(
            kind: kind,
            price: price,
            previousClose: nil,
            change: nil,
            changePercent: nil,
            high: nil,
            low: nil,
            bid: nil,
            ask: nil,
            regularPrice: nil,
            move: nil,
            sourceName: "test",
            quoteTimeLabel: "test",
            fetchedAt: fetchedAt
        )
    }

    func testBelowAlertFiresOnceAndRearms() async throws {
        let notifier = MockNotifier()
        let monitor = PriceMonitorService(notifier: notifier)
        let alert = PriceAlert(kind: .icbc, direction: .below, target: 780)

        let first = await monitor.evaluate(quotes: [.icbc: quote(779.49)], alerts: [alert])
        XCTAssertEqual(first, 1)
        XCTAssertEqual(notifier.count, 1)
        XCTAssertFalse(alert.armed)
        XCTAssertNotNil(alert.lastTriggeredPrice)
        XCTAssertNotNil(alert.lastTriggeredAt)

        let repeated = await monitor.evaluate(quotes: [.icbc: quote(775.00)], alerts: [alert])
        XCTAssertEqual(repeated, 0)
        XCTAssertEqual(notifier.count, 1)

        let rearmed = await monitor.evaluate(quotes: [.icbc: quote(785.00)], alerts: [alert])
        XCTAssertEqual(rearmed, 0)
        XCTAssertTrue(alert.armed)

        let firedAgain = await monitor.evaluate(quotes: [.icbc: quote(778.00)], alerts: [alert])
        XCTAssertEqual(firedAgain, 1)
        XCTAssertEqual(notifier.count, 2)
    }

    func testDisabledAlertNeverFires() async throws {
        let notifier = MockNotifier()
        let monitor = PriceMonitorService(notifier: notifier)
        let alert = PriceAlert(kind: .london, direction: .above, target: 3600, enabled: false)
        let sent = await monitor.evaluate(quotes: [.london: quote(3800, kind: .london)], alerts: [alert])
        XCTAssertEqual(sent, 0)
        XCTAssertEqual(notifier.count, 0)
        XCTAssertTrue(alert.armed)
    }

    func testStaleQuoteIsMarked() {
        let stale = quote(100, fetchedAt: Date().addingTimeInterval(-3_600))
        XCTAssertTrue(stale.isStale(intervalSeconds: 60))
        XCTAssertFalse(quote(100).isStale(intervalSeconds: 60))
    }
}
