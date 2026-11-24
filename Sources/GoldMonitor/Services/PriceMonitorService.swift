import Foundation

struct PriceMonitorService: Sendable {
    let notifier: any Notifying

    /// 触发后关闭武装状态避免重复通知；价格回到条件外时重新武装。
    /// - Returns: 本次实际通知条数
    func evaluate(quotes: [GoldQuote.Kind: GoldQuote], alerts: [PriceAlert]) async -> Int {
        var sent = 0
        for alert in alerts where alert.enabled {
            guard let quote = quotes[alert.kind] else { continue }
            if alert.matches(price: quote.price) {
                guard alert.armed else { continue }
                alert.armed = false
                alert.lastTriggeredAt = Date()
                alert.lastTriggeredPrice = quote.price
                await notifier.send(
                    title: "价格预警 · \(alert.kind.shortName)",
                    body: "\(alert.title)。当前 \(PriceAlert.format(quote.price, kind: alert.kind)) \(alert.kind.unit)"
                )
                sent += 1
            } else if !alert.armed {
                alert.armed = true
            }
        }
        return sent
    }
}
