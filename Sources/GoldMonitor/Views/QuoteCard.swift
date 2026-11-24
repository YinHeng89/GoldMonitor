import SwiftUI
import SwiftData

struct QuoteCard: View {
    let kind: GoldQuote.Kind
    @EnvironmentObject private var store: MarketStore
    @Query private var snapshots: [PriceSnapshot]

    init(kind: GoldQuote.Kind) {
        self.kind = kind
        _snapshots = Query(
            filter: #Predicate<PriceSnapshot> { $0.kindRaw == kind.rawValue },
            sort: \.timestamp,
            order: .reverse
        )
    }

    private var quote: GoldQuote? { store.quotes[kind] }
    private var points: [PriceSnapshot] { Array(snapshots.prefix(60).reversed()) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 7) {
                        Image(systemName: kind == .london ? "globe.americas" : "banknote")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.gold)
                        Text(kind.displayName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.text)
                    }
                    Text(quote?.sourceName ?? store.londonProviderName())
                        .font(.system(size: 10.5))
                        .foregroundStyle(Theme.secondary)
                        .lineLimit(1)
                }
                Spacer()
                StatusBadge(kind: kind)
            }

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(gmNumber(quote?.price))
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(kind.unit)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.secondary)
            }

            if quote != nil {
                HStack(spacing: 12) {
                    if let ratio = quote?.changeRatio {
                        HStack(spacing: 4) {
                            Image(systemName: ratio > 0 ? "chevron.up" : (ratio < 0 ? "chevron.down" : "minus"))
                                .font(.system(size: 11, weight: .bold))
                            Text(gmSigned(quote?.changeValue) + "  " + gmPercent(ratio))
                                .monospacedDigit()
                        }
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(Theme.priceColor(quote?.changeValue))
                    } else if let move = quote?.move {
                        HStack(spacing: 5) {
                            Image(systemName: move == .up ? "chevron.up" : (move == .down ? "chevron.down" : "minus"))
                                .font(.system(size: 11, weight: .bold))
                            Text(move == .up ? "较前值上涨" : (move == .down ? "较前值下跌" : "较前值持平"))
                        }
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(Theme.moveColor(move))
                    }
                    Spacer()
                    Text("源时间 \(quote?.quoteTimeLabel ?? "--")")
                        .font(.system(size: 10.5))
                        .foregroundStyle(Theme.muted)
                        .lineLimit(1)
                }
            }

            Divider().background(Theme.border)

            PriceChart(points: points, height: 78)

            HStack {
                if let error = store.errors[kind] {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.up)
                        .lineLimit(2)
                } else {
                    Label("最后更新 \(gmDateTime(store.lastSuccess[kind]))", systemImage: "clock")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.muted)
                }
                Spacer()
                if let high = quote?.high, let low = quote?.low {
                    Text("高 \(gmNumber(high)) · 低 \(gmNumber(low))")
                        .font(.system(size: 10))
                        .monospacedDigit()
                        .foregroundStyle(Theme.secondary)
                }
            }
        }
        .gmCard()
    }
}

struct StatusBadge: View {
    let kind: GoldQuote.Kind
    @EnvironmentObject private var store: MarketStore

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(color.opacity(0.12), in: Capsule())
    }

    private var hasError: Bool { store.errors[kind] != nil }

    private var isStale: Bool {
        guard let quote = store.quotes[kind] else { return true }
        return quote.isStale(intervalSeconds: store.settings.refreshInterval)
    }

    private var color: Color { hasError ? Theme.up : (isStale ? Theme.gold : Theme.down) }
    private var label: String { hasError ? "获取失败" : (isStale ? "数据延迟" : "正常") }
}
