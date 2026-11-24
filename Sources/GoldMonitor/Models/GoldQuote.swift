import Foundation

struct GoldQuote: Identifiable, Codable, Sendable, Equatable {
    enum Kind: String, Codable, CaseIterable, Sendable, Identifiable {
        case london
        case icbc

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .london: return "伦敦金 XAUUSD"
            case .icbc: return "工行积存金"
            }
        }

        var shortName: String {
            switch self {
            case .london: return "伦敦金"
            case .icbc: return "积存金"
            }
        }

        var unit: String {
            switch self {
            case .london: return "美元/盎司"
            case .icbc: return "元/克"
            }
        }
    }

    enum PriceMove: Int, Codable, Sendable {
        case down = -1
        case flat = 0
        case up = 1
    }

    let kind: Kind
    let price: Double
    let previousClose: Double?
    let change: Double?
    let changePercent: Double?
    let high: Double?
    let low: Double?
    let bid: Double?
    let ask: Double?
    let regularPrice: Double?
    let move: PriceMove?
    let sourceName: String
    let quoteTimeLabel: String
    let fetchedAt: Date

    var id: String { kind.rawValue }

    var changeValue: Double? {
        if let change { return change }
        if let previousClose, previousClose != 0 { return price - previousClose }
        return nil
    }

    var changeRatio: Double? {
        if let changePercent { return changePercent }
        if let previousClose, previousClose != 0 { return (price - previousClose) / previousClose }
        return nil
    }

    func isStale(intervalSeconds: Int) -> Bool {
        Date().timeIntervalSince(fetchedAt) > Double(max(intervalSeconds, 60) * 3)
    }
}

struct QuoteFetchError: LocalizedError {
    let kind: GoldQuote.Kind
    let detail: String

    var errorDescription: String? { "\(kind.shortName)数据获取失败：\(detail)" }
}
