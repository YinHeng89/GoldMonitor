import SwiftUI
import SwiftData

struct DashboardView: View {
    @EnvironmentObject private var store: MarketStore
    @Query(sort: \GoldHolding.createdAt, order: .reverse) private var holdings: [GoldHolding]
    var onOpenHoldings: (() -> Void)? = nil

    private var summary: HoldingSummary {
        HoldingSummary.make(holdings, quotes: store.quotes)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                holdingsOverview
                LazyVGrid(columns: [GridItem(.flexible(minimum: 320), spacing: 18), GridItem(.flexible(minimum: 320))], spacing: 18) {
                    QuoteCard(kind: .london)
                    QuoteCard(kind: .icbc)
                }
                statusBar
                Spacer(minLength: 12)
            }
            .padding(26)
        }
        .background(Theme.background)
    }

    private var header: some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: 5) {
                Text("行情总览")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.text)
                Text("伦敦金现货与中国工商银行积存金 · 数据来自公开行情页面")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.secondary)
            }
            Spacer()
            Button {
                Task { await store.refresh() }
            } label: {
                Label(store.isRefreshing ? "刷新中" : "立即刷新", systemImage: "arrow.clockwise")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.gold)
            .disabled(store.isRefreshing)
            .controlSize(.large)
        }
    }

    private var holdingsOverview: some View {
        Button {
            onOpenHoldings?()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "briefcase")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.gold)
                    Text("我的持仓")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.text)
                    Spacer()
                    Text(holdings.isEmpty ? "去录入" : "查看详情")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.gold)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.gold)
                }

                if holdings.isEmpty {
                    Text("录入成本价与克数后，这里会实时显示你的浮动盈亏")
                        .font(.system(size: 11.5))
                        .foregroundStyle(Theme.secondary)
                } else {
                    HStack(spacing: 0) {
                        dashMetric("持仓成本", gmNumber(summary.cost), Theme.text)
                        dashMetric("当前市值", gmNumber(summary.marketValue), Theme.text)
                        dashMetric("浮动盈亏", gmSigned(summary.profit), Theme.priceColor(summary.profit))
                        dashMetric("收益率", gmPercent(summary.profitPercent), Theme.priceColor(summary.profit))
                    }
                    if summary.hasUnpriced {
                        Text("\(summary.pricedCount)/\(summary.totalCount) 笔已获取行情")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.muted)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .gmCard(padding: 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func dashMetric(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 10.5))
                .foregroundStyle(Theme.secondary)
            Text(value)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statusBar: some View {
        HStack(spacing: 14) {
            ForEach(GoldQuote.Kind.allCases) { kind in
                HStack(spacing: 6) {
                    StatusBadge(kind: kind)
                    Text(kind.shortName)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.secondary)
                }
            }
            Spacer(minLength: 8)
            if let error = store.errors.values.first {
                Text(error)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.up)
                    .lineLimit(1)
            } else {
                Text("刷新间隔 \(store.settings.refreshInterval)s · \(store.settings.autoRefresh ? "自动刷新" : "手动刷新")")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }
}
