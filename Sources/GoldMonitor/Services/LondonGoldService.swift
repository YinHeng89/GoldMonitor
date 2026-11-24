import Foundation

protocol LondonGoldProviding: Sendable {
    var sourceName: String { get }
    func fetch() async throws -> GoldQuote
}

enum LondonParseError: LocalizedError {
    case payloadNotFound
    case fieldMissing(Int)

    var errorDescription: String? {
        switch self {
        case .payloadNotFound: return "行情字符串中未找到数据载荷"
        case .fieldMissing(let index): return "行情字段 \(index) 缺失或格式异常"
        }
    }
}

struct SinaLondonGoldService: LondonGoldProviding {
    let sourceName = "新浪财经 · 伦敦金现货 hf_XAU"
    private let client: any HTTPFetching

    init(client: any HTTPFetching = URLSessionHTTPClient()) {
        self.client = client
    }

    func fetch() async throws -> GoldQuote {
        var request = URLRequest(url: URL(string: "https://hq.sinajs.cn/list=hf_XAU")!)
        request.setValue("https://finance.sina.com.cn/", forHTTPHeaderField: "Referer")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
        let (data, _) = try await client.data(for: request)
        // 新浪返回 GBK；行情字段全部是 ASCII，中文名称无需解析，用无损解码保留结构。
        let text = String(decoding: data, as: UTF8.self)
        return try Self.parse(text, sourceName: sourceName)
    }

    /// hf_XAU 字段：0 最新价, 1 昨收, 2 今开, 4 最高, 5 最低, 6 时间, 12 日期。
    static func parse(_ text: String, sourceName: String = "新浪财经 · 伦敦金现货 hf_XAU") throws -> GoldQuote {
        let regex = try NSRegularExpression(pattern: #"hq_str_hf_XAU="([^"]*)""#)
        let ns = text as NSString
        guard let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)),
              match.numberOfRanges > 1
        else { throw LondonParseError.payloadNotFound }

        let payload = ns.substring(with: match.range(at: 1))
        let fields = payload.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
        guard fields.count >= 13 else { throw LondonParseError.fieldMissing(fields.count) }

        func number(_ index: Int) throws -> Double {
            guard let value = Double(fields[index].trimmingCharacters(in: .whitespaces)), value.isFinite else {
                throw LondonParseError.fieldMissing(index)
            }
            return value
        }

        let price = try number(0)
        let previous = try number(1)
        guard price > 0, previous > 0 else { throw LondonParseError.fieldMissing(0) }
        let change = price - previous
        return GoldQuote(
            kind: .london,
            price: price,
            previousClose: previous,
            change: change,
            changePercent: change / previous,
            high: Double(fields[4]),
            low: Double(fields[5]),
            bid: nil,
            ask: nil,
            regularPrice: nil,
            move: change > 0 ? .up : (change < 0 ? .down : .flat),
            sourceName: sourceName,
            quoteTimeLabel: "\(fields[12]) \(fields[6])",
            fetchedAt: Date()
        )
    }
}
