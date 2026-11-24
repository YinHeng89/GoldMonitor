import Foundation

enum FX168ParseError: LocalizedError {
    case priceNotFound

    var errorDescription: String? {
        "FX168 页面未解析到伦敦金价格，页面结构可能已变化"
    }
}

/// 规划文档中指定的备用来源。仅做只读网页解析，解析失败时明确报错，绝不返回旧值冒充实时数据。
struct FX168Service: LondonGoldProviding {
    let sourceName = "FX168 · 伦敦金行情页（实验性）"
    private let client: any HTTPFetching

    init(client: any HTTPFetching = URLSessionHTTPClient()) {
        self.client = client
    }

    func fetch() async throws -> GoldQuote {
        var request = URLRequest(url: URL(string: "https://www.fx168news.com/quote/XAU")!)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
        let (data, _) = try await client.data(for: request)
        let text = String(data: data, encoding: .utf8) ?? String(decoding: data, as: UTF8.self)
        return try Self.parse(text, sourceName: sourceName)
    }

    static func parse(_ html: String, sourceName: String = "FX168 · 伦敦金行情页（实验性）") throws -> GoldQuote {
        let patterns = [
            #"(?i)(?:lastPrice|last_price|lastprice|last)["':>\s]{1,12}([0-9]{3,6}\.[0-9]{1,3})"#,
            #"(?i)XAUUSD[\s\S]{0,400}?([0-9]{3,6}\.[0-9]{1,3})"#
        ]
        var price: Double?
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: html, range: NSRange(location: 0, length: (html as NSString).length)),
                  match.numberOfRanges > 1,
                  let found = Double((html as NSString).substring(with: match.range(at: 1))),
                  (100...100_000).contains(found)
            else { continue }
            price = found
            break
        }
        guard let price else { throw FX168ParseError.priceNotFound }
        return GoldQuote(
            kind: .london,
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
            sourceName: sourceName,
            quoteTimeLabel: "页面未标注时间",
            fetchedAt: Date()
        )
    }
}
