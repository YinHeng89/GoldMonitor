import Foundation

protocol ICBCGoldProviding: Sendable {
    func fetch() async throws -> GoldQuote
}

enum ICBCParseError: LocalizedError {
    case transactionFailed(String)
    case noRecord
    case invalidPrice

    var errorDescription: String? {
        switch self {
        case .transactionFailed(let message): return "工行接口返回错误：\(message)"
        case .noRecord: return "工行接口未返回积存金行情"
        case .invalidPrice: return "工行行情价格字段无效"
        }
    }
}

struct ICBCGoldService: ICBCGoldProviding {
    private let client: any HTTPFetching
    let sourceName = "中国工商银行 · 积存金官网行情"

    init(client: any HTTPFetching = URLSessionHTTPClient()) {
        self.client = client
    }

    func fetch() async throws -> GoldQuote {
        var request = URLRequest(url: URL(string: "https://mybank.icbc.com.cn/servlet/AsynGetDataServlet")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.setValue("https://mybank.icbc.com.cn/icbc/newperbank/gold/goldaccrual_marketpriceinfo_unlogin.jsp", forHTTPHeaderField: "Referer")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
        request.httpBody = "tranCode=A00622".data(using: .utf8)
        let (data, _) = try await client.data(for: request)
        return try Self.parse(data, sourceName: sourceName)
    }

    static func parse(_ data: Data, sourceName: String = "中国工商银行 · 积存金官网行情") throws -> GoldQuote {
        let payload: ICBCPayload
        do {
            payload = try JSONDecoder().decode(ICBCPayload.self, from: data)
        } catch {
            throw ICBCParseError.transactionFailed("响应不是合法 JSON（\(error.localizedDescription)）")
        }
        if !payload.tranErrorCode.isEmpty {
            throw ICBCParseError.transactionFailed(payload.tranErrorDisplayMsg.isEmpty ? payload.tranErrorCode : payload.tranErrorDisplayMsg)
        }
        guard let record = payload.rf.first(where: { Double($0.activePrice) != nil }) else {
            throw ICBCParseError.noRecord
        }
        guard let price = Double(record.activePrice), price > 0 else { throw ICBCParseError.invalidPrice }

        let time = payload.sysdate.split(separator: " ").last.map(String.init) ?? ""
        let label = time.isEmpty ? record.activeDate : "\(record.activeDate) \(time)"
        let move: GoldQuote.PriceMove = record.active == "1" ? .up : (record.active == "2" ? .down : .flat)

        return GoldQuote(
            kind: .icbc,
            price: price,
            previousClose: nil,
            change: nil,
            changePercent: nil,
            high: Double(record.highPrice),
            low: Double(record.lowPrice),
            bid: price,
            ask: Double(record.sellPrice),
            regularPrice: Double(record.regPrice),
            move: move,
            sourceName: sourceName,
            quoteTimeLabel: label,
            fetchedAt: Date()
        )
    }
}

private struct ICBCPayload: Decodable {
    let sysdate: String
    let tranErrorCode: String
    let tranErrorDisplayMsg: String
    let rf: [ICBCRecord]

    enum CodingKeys: String, CodingKey {
        case sysdate
        case tranErrorCode = "TranErrorCode"
        case tranErrorDisplayMsg = "TranErrorDisplayMsg"
        case rf
    }
}

private struct ICBCRecord: Decodable {
    let goldTypeNo: String
    let productName: String
    let activePrice: String
    let sellPrice: String
    let highPrice: String
    let lowPrice: String
    let regPrice: String
    let activeDate: String
    let active: String

    enum CodingKeys: String, CodingKey {
        case goldTypeNo
        case productName = "ProductName"
        case activePrice = "ActivePrice"
        case sellPrice = "SellPrice"
        case highPrice = "HighPrice"
        case lowPrice = "LowPrice"
        case regPrice = "RegPrice"
        case activeDate = "ActiveDate"
        case active = "Active"
    }
}
