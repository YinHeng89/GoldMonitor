import SwiftUI
import SwiftData

struct MenuBarView: View {
    @EnvironmentObject private var store: MarketStore
    @Environment(\.openWindow) private var openWindow
    @Query private var holdings: [GoldHolding]

    private var summary: HoldingSummary {
        HoldingSummary.make(holdings, quotes: store.quotes)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题
            HStack(spacing: 6) {
                Image(systemName: "banknote.fill")
                    .foregroundStyle(Theme.gold)
                Text("Gold Monitor")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.gold)
                Spacer(minLength: 12)
                Text("实时行情")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 8)

            Divider()

            // 两个品种：名称 + 金色价格 + 涨跌
            ForEach(GoldQuote.Kind.allCases) { kind in
                quoteRow(kind)
            }

            // 持仓盈亏（有持仓才显示）
            if !holdings.isEmpty {
                Divider()
                holdingRow
            }

            Divider()

            // 更新时间合并为一行
            updateRow

            Divider()

            // 操作区
            VStack(alignment: .leading, spacing: 2) {
                Button {
                    openWindow(id: "main")
                    NSApp.activate(ignoringOtherApps: true)
                } label: {
                    Label("打开主窗口", systemImage: "macwindow")
                }
                Button {
                    Task { await store.refresh() }
                } label: {
                    Label("立即刷新", systemImage: "arrow.clockwise")
                }
                .disabled(store.isRefreshing)
            }
            .padding(.vertical, 4)

            Divider()

            Button("退出 Gold Monitor") {
                NSApp.terminate(nil)
            }
        }
        .tint(Theme.gold)
    }

    private func quoteRow(_ kind: GoldQuote.Kind) -> some View {
        let quote = store.quotes[kind]
        let failed = store.errors[kind] != nil
        let change = quote?.changeValue
        let ratio = quote?.changeRatio
        return VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Circle()
                    .fill(failed ? Theme.muted : Theme.gold)
                    .frame(width: 6, height: 6)
                Text(kind.shortName)
                    .font(.system(size: 11.5, weight: .medium))
                Spacer(minLength: 10)
                if failed {
                    Text("获取失败")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.up)
                } else {
                    Text(gmNumber(quote?.price))
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Theme.gold)
                    Text(kind.unit)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            if !failed {
                Group {
                    if change != nil {
                        HStack(spacing: 8) {
                            Text(gmSigned(change))
                            Text(gmPercent(ratio))
                        }
                        .foregroundStyle(Theme.priceColor(change))
                    } else {
                        Text("涨跌 --")
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.system(size: 10.5, design: .monospaced))
                .padding(.leading, 12)
            }
        }
        .padding(.vertical, 5)
    }

    private var holdingRow: some View {
        HStack(spacing: 8) {
            Text("持仓盈亏")
                .font(.system(size: 11.5))
            Spacer(minLength: 10)
            if summary.pricedCount > 0 {
                Text(gmSigned(summary.profit))
                    .foregroundStyle(Theme.priceColor(summary.profit))
                Text(gmPercent(summary.profitPercent))
                    .foregroundStyle(Theme.priceColor(summary.profit))
            } else {
                Text("待行情")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .font(.system(size: 11.5, weight: .medium, design: .monospaced))
        .padding(.vertical, 5)
    }

    private var updateRow: some View {
        let times = [store.lastSuccess[.london], store.lastSuccess[.icbc]].compactMap { $0 }
        let label: String = {
            guard let earliest = times.min() else { return "尚未获取行情" }
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            return "更新于 \(formatter.string(from: earliest))"
        }()
        return Text(label)
            .font(.system(size: 10))
            .foregroundStyle(.secondary)
            .padding(.vertical, 4)
    }
}
