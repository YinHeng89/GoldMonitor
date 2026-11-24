import Foundation
import SwiftData

/// 手动录入的一笔黄金持仓。数据存在本地 SwiftData 库，不连接银行账户。
@Model
final class GoldHolding {
    var kindRaw: String
    var costPrice: Double
    var grams: Double
    var note: String
    var purchasedAt: Date?
    var createdAt: Date
    var updatedAt: Date

    init(
        kind: GoldQuote.Kind = .icbc,
        costPrice: Double,
        grams: Double,
        note: String = "",
        purchasedAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.kindRaw = kind.rawValue
        self.costPrice = costPrice
        self.grams = grams
        self.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        self.purchasedAt = purchasedAt
        self.createdAt = createdAt
        self.updatedAt = createdAt
    }

    var kind: GoldQuote.Kind {
        get { GoldQuote.Kind(rawValue: kindRaw) ?? .icbc }
        set {
            kindRaw = newValue.rawValue
            updatedAt = Date()
        }
    }

    /// 买入总成本。
    var cost: Double { costPrice * grams }

    /// 当前可变现价：工行用赎回价（SellPrice → ask），伦敦金用现价。
    func realizablePrice(from quote: GoldQuote?) -> Double? {
        guard let quote, quote.kind == kind else { return nil }
        let value = kind == .icbc ? (quote.ask ?? quote.price) : (quote.bid ?? quote.price)
        guard value.isFinite, value > 0 else { return nil }
        return value
    }

    func metrics(quote: GoldQuote?) -> HoldingMetrics {
        let cost = self.cost
        guard let price = realizablePrice(from: quote), cost > 0 else {
            return HoldingMetrics(cost: cost, price: nil, marketValue: nil, profit: nil, profitPercent: nil)
        }
        let marketValue = price * grams
        let profit = marketValue - cost
        return HoldingMetrics(
            cost: cost,
            price: price,
            marketValue: marketValue,
            profit: profit,
            profitPercent: profit / cost
        )
    }
}

struct HoldingMetrics {
    let cost: Double
    let price: Double?
    let marketValue: Double?
    let profit: Double?
    let profitPercent: Double?

    var isPriced: Bool { marketValue != nil }
}

struct HoldingSummary {
    /// 已获取行情的持仓成本合计（与市值、盈亏口径一致）。
    let cost: Double
    let marketValue: Double
    let profit: Double
    let profitPercent: Double?
    let pricedCount: Int
    let totalCount: Int
    /// 全部持仓成本，含尚未获取行情的笔数。
    let totalCost: Double

    var hasUnpriced: Bool { pricedCount < totalCount }

    static func make(_ holdings: [GoldHolding], quotes: [GoldQuote.Kind: GoldQuote]) -> HoldingSummary {
        let priced = holdings.compactMap { holding -> HoldingMetrics? in
            let metrics = holding.metrics(quote: quotes[holding.kind])
            return metrics.isPriced ? metrics : nil
        }
        let cost = priced.reduce(0) { $0 + $1.cost }
        let marketValue = priced.reduce(0) { $0 + ($1.marketValue ?? 0) }
        let profit = marketValue - cost
        return HoldingSummary(
            cost: cost,
            marketValue: marketValue,
            profit: profit,
            profitPercent: cost > 0 ? profit / cost : nil,
            pricedCount: priced.count,
            totalCount: holdings.count,
            totalCost: holdings.reduce(0) { $0 + $1.cost }
        )
    }
}
