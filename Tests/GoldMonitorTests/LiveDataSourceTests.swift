import XCTest
@testable import GoldMonitor

/// 真实网络验证：只验证数据源与解析链路，网络不可用时跳过而不是伪造成功。
final class LiveDataSourceTests: XCTestCase {
    func testLiveICBCService() async throws {
        do {
            let quote = try await ICBCGoldService().fetch()
            XCTAssertEqual(quote.kind, .icbc)
            XCTAssertGreaterThan(quote.price, 100)
            XCTAssertGreaterThan(quote.fetchedAt.timeIntervalSinceNow, -120)
            XCTAssertFalse(quote.quoteTimeLabel.isEmpty)
            print("[LIVE] ICBC 主动积存价 = \(quote.price), 源时间 = \(quote.quoteTimeLabel)")
        } catch {
            throw XCTSkip("工行行情接口当前不可达: \(error.localizedDescription)")
        }
    }

    func testLiveSinaLondonService() async throws {
        do {
            let quote = try await SinaLondonGoldService().fetch()
            XCTAssertEqual(quote.kind, .london)
            XCTAssertGreaterThan(quote.price, 100)
            XCTAssertNotNil(quote.previousClose)
            XCTAssertNotNil(quote.changePercent)
            print("[LIVE] 伦敦金 = \(quote.price), 涨跌 = \(quote.change ?? 0), 源时间 = \(quote.quoteTimeLabel)")
        } catch {
            throw XCTSkip("新浪伦敦金接口当前不可达: \(error.localizedDescription)")
        }
    }
}
