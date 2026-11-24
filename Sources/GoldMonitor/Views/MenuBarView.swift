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
            HStack(spacing: 6) {
                Image(systemName: "banknote.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.gold)
                Text("Gold Monitor")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.gold)
                Spacer(minLength: 8)
                Text(timeLabel)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.muted)
            }

            Divider()
                .background(Theme.border)
                .padding(.vertical, 8)

            VStack(spacing: 7) {
                quoteLine(.london)
                quoteLine(.icbc)
                if !holdings.isEmpty { holdingLine }
            }

            Divider()
                .background(Theme.border)
                .padding(.vertical, 8)

            HStack(spacing: 10) {
                Button {
                    openWindow(id: "main")
                    NSApp.activate(ignoringOtherApps: true)
                } label: {
                    Label("主窗口", systemImage: "macwindow")
                }
                Button {
                    Task { await store.refresh() }
                } label: {
                    Label("刷新", systemImage: "arrow.clockwise")
                }
                .disabled(store.isRefreshing)
                Spacer(minLength: 4)
                Button("退出") { NSApp.terminate(nil) }
            }
            .buttonStyle(.borderless)
            .font(.system(size: 11))
        }
        .padding(12)
        .frame(width: 292, alignment: .leading)
        .background(Theme.panel)
        .tint(Theme.gold)
        .environment(\.colorScheme, .dark)
    }

    private func quoteLine(_ kind: GoldQuote.Kind) -> some View {
        let quote = store.quotes[kind]
        let failed = store.errors[kind] != nil
        let ratio = quote?.changeRatio
        return HStack(spacing: 6) {
            Circle()
                .fill(failed ? Theme.muted : Theme.gold)
                .frame(width: 5, height: 5)
            Text(kind.shortName)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(Theme.text)
                .frame(width: 42, alignment: .leading)
            if failed {
                Text("获取失败")
                    .font(.system(size: 10.5))
                    .foregroundStyle(Theme.up)
            } else {
                Text(gmNumber(quote?.price))
                    .font(.system(size: 12.5, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.gold)
                Text(kind.unit)
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.muted)
                Spacer(minLength: 4)
                Text(ratio == nil ? "--" : gmPercent(ratio))
                    .font(.system(size: 10.5, design: .monospaced))
                    .foregroundStyle(Theme.priceColor(ratio))
            }
        }
    }

    private var holdingLine: some View {
        HStack(spacing: 6) {
            Text("持仓")
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(Theme.text)
                .frame(width: 42, alignment: .leading)
            if summary.pricedCount > 0 {
                Text(gmSigned(summary.profit))
                    .foregroundStyle(Theme.priceColor(summary.profit))
                Spacer(minLength: 4)
                Text(gmPercent(summary.profitPercent))
                    .font(.system(size: 10.5, design: .monospaced))
                    .foregroundStyle(Theme.priceColor(summary.profit))
            } else {
                Text("待行情")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.muted)
            }
        }
        .font(.system(size: 11.5, weight: .medium, design: .monospaced))
        .padding(.leading, 11)
    }

    private var timeLabel: String {
        let times = [store.lastSuccess[.london], store.lastSuccess[.icbc]].compactMap { $0 }
        guard let earliest = times.min() else { return "--:--:--" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: earliest)
    }
}
