import XCTest
@testable import GoldMonitor

final class HoldingTests: XCTestCase {

    private func quote(
        _ kind: GoldQuote.Kind,
        price: Double,
        bid: Double? = nil,
        ask: Double? = nil
    ) -> GoldQuote {
        GoldQuote(
            kind: kind,
            price: price,
            previousClose: nil,
            change: nil,
            changePercent: nil,
            high: nil,
            low: nil,
            bid: bid,
            ask: ask,
            regularPrice: nil,
            move: nil,
            sourceName: "测试行情",
            quoteTimeLabel: "",
            fetchedAt: Date()
        )
    }

    func testProfitUsesRedemptionPrice() {
        let holding = GoldHolding(kind: .icbc, costPrice: 700, grams: 10)
        // 主动积存价 778、赎回价 780：收益必须按 780 算。
        let q = quote(.icbc, price: 778, bid: 778, ask: 780)
        let metrics = holding.metrics(quote: q)

        XCTAssertEqual(metrics.cost, 7000, accuracy: 0.001)
        XCTAssertEqual(metrics.price ?? -1, 780, accuracy: 0.001)
        XCTAssertEqual(metrics.marketValue ?? -1, 7800, accuracy: 0.001)
        XCTAssertEqual(metrics.profit ?? -1, 800, accuracy: 0.001)
        XCTAssertEqual(metrics.profitPercent ?? 0, 800.0 / 7000.0, accuracy: 0.000001)
    }

    func testLossAndNegativeRate() {
        let holding = GoldHolding(kind: .icbc, costPrice: 800, grams: 5, note: "测试亏损")
        let metrics = holding.metrics(quote: quote(.icbc, price: 750, ask: 750))

        XCTAssertEqual(metrics.cost, 4000, accuracy: 0.001)
        XCTAssertEqual(metrics.profit ?? 0, -250, accuracy: 0.001)
        XCTAssertTrue(metrics.profitPercent! < 0)
        XCTAssertEqual(holding.note, "测试亏损")
    }

    func testLondonUsesBidAndFallsBackToPrice() {
        let holding = GoldHolding(kind: .london, costPrice: 3500, grams: 2)
        let withBid = holding.metrics(quote: quote(.london, price: 3620, bid: 3600, ask: 3650))
        XCTAssertEqual(withBid.price ?? -1, 3600, accuracy: 0.001)
        XCTAssertEqual(withBid.profit ?? 0, 200, accuracy: 0.001)

        let fallback = holding.metrics(quote: quote(.london, price: 3620))
        XCTAssertEqual(fallback.price ?? -1, 3620, accuracy: 0.001)
    }

    func testMissingOrInvalidQuoteIsNotPriced() {
        let holding = GoldHolding(kind: .icbc, costPrice: 700, grams: 10)

        let none = holding.metrics(quote: nil)
        XCTAssertFalse(none.isPriced)
        XCTAssertNil(none.profit)

        let wrongKind = holding.metrics(quote: quote(.london, price: 780))
        XCTAssertFalse(wrongKind.isPriced)

        let zeroAsk = holding.metrics(quote: quote(.icbc, price: 780, ask: 0))
        XCTAssertFalse(zeroAsk.isPriced)
        XCTAssertEqual(zeroAsk.cost, 7000, accuracy: 0.001)
    }

    func testZeroCostDoesNotDivideByZero() {
        let holding = GoldHolding(kind: .icbc, costPrice: 0, grams: 10)
        let metrics = holding.metrics(quote: quote(.icbc, price: 780, ask: 780))
        XCTAssertNil(metrics.profitPercent)
        XCTAssertNil(metrics.marketValue)
    }

    func testSummaryOnlyCountsPricedHoldings() {
        let a = GoldHolding(kind: .icbc, costPrice: 700, grams: 10)   // 成本 7000，市值 7800
        let b = GoldHolding(kind: .icbc, costPrice: 750, grams: 4)    // 成本 3000，市值 3120
        let c = GoldHolding(kind: .london, costPrice: 3500, grams: 1) // 无行情
        let summary = HoldingSummary.make([a, b, c], quotes: [
            .icbc: quote(.icbc, price: 778, ask: 780)
        ])

        XCTAssertEqual(summary.pricedCount, 2)
        XCTAssertEqual(summary.totalCount, 3)
        XCTAssertEqual(summary.cost, 10000, accuracy: 0.001)
        XCTAssertEqual(summary.marketValue, 10920, accuracy: 0.001)
        XCTAssertEqual(summary.profit, 920, accuracy: 0.001)
        XCTAssertEqual(summary.profitPercent ?? 0, 0.092, accuracy: 0.000001)
        XCTAssertEqual(summary.totalCost, 13500, accuracy: 0.001)
        XCTAssertTrue(summary.hasUnpriced)
    }

    func testEmptySummaryIsSafe() {
        let summary = HoldingSummary.make([], quotes: [:])
        XCTAssertEqual(summary.cost, 0)
        XCTAssertEqual(summary.profit, 0)
        XCTAssertNil(summary.profitPercent)
        XCTAssertFalse(summary.hasUnpriced)
    }
}
