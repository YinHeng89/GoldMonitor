import SwiftUI
import SwiftData

struct QuoteDetailView: View {
    let kind: GoldQuote.Kind
    @EnvironmentObject private var store: MarketStore
    @Query private var snapshots: [PriceSnapshot]
    @State private var range: HistoryRange = .day

    init(kind: GoldQuote.Kind) {
        self.kind = kind
        _snapshots = Query(
            filter: #Predicate<PriceSnapshot> { $0.kindRaw == kind.rawValue },
            sort: \.timestamp,
            order: .reverse
        )
    }

    private var quote: GoldQuote? { store.quotes[kind] }
    private var points: [PriceSnapshot] {
        let cutoff = Date().addingTimeInterval(-range.seconds)
        return snapshots.filter { $0.timestamp >= cutoff }.reversed()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .lastTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(kind.displayName)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.text)
                        Text(quote?.sourceName ?? "等待首次刷新")
                            .font(.system(size: 11.5))
                            .foregroundStyle(Theme.secondary)
                    }
                    Spacer()
                    StatusBadge(kind: kind)
                }

                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(gmNumber(quote?.price))
                        .font(.system(size: 52, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Theme.text)
                        .minimumScaleFactor(0.7)
                    Text(kind.unit)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.secondary)
                    if let ratio = quote?.changeRatio {
                        Text(gmSigned(quote?.changeValue) + " (" + gmPercent(ratio) + ")")
                            .font(.system(size: 15, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(Theme.priceColor(quote?.changeValue))
                    } else if let move = quote?.move {
                        Image(systemName: move == .up ? "chevron.up" : (move == .down ? "chevron.down" : "minus"))
                            .foregroundStyle(Theme.moveColor(move))
                    }
                }

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("价格走势")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.text)
                        Spacer()
                        Picker("", selection: $range) {
                            ForEach(HistoryRange.allCases) { item in
                                Text(item.title).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 260)
                    }
                    PriceChart(points: points, height: 260, showAxis: true)
                }
                .gmCard()

                metrics

                if let error = store.errors[kind] {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("\(error) · 当前显示的是最后一次成功获取的数据（\(gmFullDateTime(store.lastSuccess[kind]))），不是实时价格。")
                    }
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.up)
                    .gmCard(padding: 12)
                }

                Spacer(minLength: 10)
            }
            .padding(26)
        }
        .background(Theme.background)
        .tint(Theme.gold)
    }

    private var metrics: some View {
        let items: [(String, String)] = {
            guard let quote else { return [] }
            if kind == .london {
                return [
                    ("最新价", gmNumber(quote.price) + " " + kind.unit),
                    ("昨收", gmNumber(quote.previousClose)),
                    ("涨跌额", gmSigned(quote.changeValue)),
                    ("涨跌幅", gmPercent(quote.changeRatio)),
                    ("最高价", gmNumber(quote.high)),
                    ("最低价", gmNumber(quote.low)),
                    ("源时间", quote.quoteTimeLabel),
                    ("最后更新", gmFullDateTime(quote.fetchedAt))
                ]
            }
            return [
                ("实时主动积存价", gmNumber(quote.price) + " 元/克"),
                ("赎回价", gmNumber(quote.ask) + " 元/克"),
                ("定期积存价", gmNumber(quote.regularPrice) + " 元/克"),
                ("最高价", gmNumber(quote.high) + " 元/克"),
                ("最低价", gmNumber(quote.low) + " 元/克"),
                ("涨跌方向", quote.move == .up ? "上涨" : (quote.move == .down ? "下跌" : "持平")),
                ("源时间", quote.quoteTimeLabel),
                ("最后更新", gmFullDateTime(quote.fetchedAt))
            ]
        }()

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            ForEach(items, id: \.0) { item in
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.0)
                        .font(.system(size: 10.5))
                        .foregroundStyle(Theme.secondary)
                    Text(item.1)
                        .font(.system(size: 13, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(Theme.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .gmCard(padding: 12, radius: 10)
            }
        }
    }
}

enum HistoryRange: String, CaseIterable, Identifiable {
    case day = "1日"
    case week = "7日"
    case month = "30日"
    case all = "全部"

    var id: String { rawValue }
    var title: String { rawValue }

    var seconds: TimeInterval {
        switch self {
        case .day: return 86_400
        case .week: return 604_800
        case .month: return 2_592_000
        // greatestFiniteMagnitude 减去后会得到非法 Date（description 为空），
        // 用「现在距 Date.distantPast 的秒数」得到合法且覆盖全量数据的 cutoff。
        case .all: return Date().timeIntervalSince(Date.distantPast)
        }
    }
}
