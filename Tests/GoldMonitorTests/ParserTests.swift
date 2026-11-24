import XCTest
@testable import GoldMonitor

final class ParserTests: XCTestCase {
    private func assertClose(_ actual: Double?, _ expected: Double, accuracy: Double = 0.001, file: StaticString = #filePath, line: UInt = #line) {
        guard let actual else {
            XCTFail("期望 \(expected)，实际为 nil", file: file, line: line)
            return
        }
        XCTAssertEqual(actual, expected, accuracy: accuracy, file: file, line: line)
    }

    func testSinaLondonQuoteParsing() throws {
        let sample = #"var hq_str_hf_XAU="3631.87,3635.230,3631.87,3632.22,3678.10,3619.71,13:28:00,3635.23,3630.52,0,0,0,2026-11-24,伦敦金（现货黄金）";"#
        let quote = try SinaLondonGoldService.parse(sample)
        XCTAssertEqual(quote.kind, .london)
        assertClose(quote.price, 3631.87)
        assertClose(quote.previousClose, 3635.23)
        assertClose(quote.change, -3.36, accuracy: 0.01)
        assertClose(quote.high, 3678.10)
        assertClose(quote.low, 3619.71)
        XCTAssertEqual(quote.quoteTimeLabel, "2026-11-24 13:28:00")
        XCTAssertEqual(quote.move, .down)
    }

    func testSinaRejectsMalformedPayload() {
        XCTAssertThrowsError(try SinaLondonGoldService.parse("var hq_str_hf_XAU=;"))
    }

    func testICBCQuoteParsing() throws {
        let json = """
        {"sysdate":"2026-11-24 13:28:25","TranErrorCode":"","rf":[{"goldTypeNo":"JC001","RegPrice":"786.00","Active":"0","ProductName":"积存金","proCode":"080020000521","Reg":"1","HighPrice":"789.90","RegDate":"2026-11-24","ActivePrice":"779.49","SellPrice":"779.49","ActiveDate":"2026-11-24","LowPrice":"777.52"}],"TranErrorDisplayMsg":""}
        """
        let quote = try ICBCGoldService.parse(Data(json.utf8))
        XCTAssertEqual(quote.kind, .icbc)
        assertClose(quote.price, 779.49)
        assertClose(quote.ask, 779.49)
        assertClose(quote.high, 789.90)
        assertClose(quote.low, 777.52)
        assertClose(quote.regularPrice, 786.00)
        XCTAssertEqual(quote.quoteTimeLabel, "2026-11-24 13:28:25")
        XCTAssertEqual(quote.move, .flat)
    }

    func testICBCTransactionError() {
        let json = #"{"sysdate":"","TranErrorCode":"E001","TranErrorDisplayMsg":"系统繁忙","rf":[]}"#
        XCTAssertThrowsError(try ICBCGoldService.parse(Data(json.utf8))) { error in
            XCTAssertTrue(error.localizedDescription.contains("系统繁忙"))
        }
    }

    func testFX168FallbackParser() throws {
        let html = #"<html><div class="quote"><span id="lastPrice">3652.18</span></div></html>"#
        let quote = try FX168Service.parse(html)
        assertClose(quote.price, 3652.18)
        XCTAssertEqual(quote.kind, .london)
        XCTAssertNil(quote.previousClose)
    }

    func testFX168RejectsEmptyPage() {
        XCTAssertThrowsError(try FX168Service.parse("<html>无行情</html>"))
    }
}
