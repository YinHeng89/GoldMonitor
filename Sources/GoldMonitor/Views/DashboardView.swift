import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: MarketStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                LazyVGrid(columns: [GridItem(.flexible(minimum: 320), spacing: 18), GridItem(.flexible(minimum: 320))], spacing: 18) {
                    QuoteCard(kind: .london)
                    QuoteCard(kind: .icbc)
                }
                diagnostics
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

    private var diagnostics: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("数据状态与诊断", systemImage: "waveform.path.ecg")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.text)
                Spacer()
                Text("刷新间隔 \(store.settings.refreshInterval) 秒 · \(store.settings.autoRefresh ? "自动刷新已开启" : "自动刷新已关闭")")
                    .font(.system(size: 10.5))
                    .foregroundStyle(Theme.muted)
            }
            ForEach(GoldQuote.Kind.allCases) { kind in
                HStack(spacing: 10) {
                    StatusBadge(kind: kind)
                    Text(kind.shortName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.text)
                        .frame(width: 76, alignment: .leading)
                    Text(kind == .london ? store.londonProviderName() : "工行官网 AsynGetDataServlet")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.secondary)
                        .lineLimit(1)
                    Spacer()
                    if let error = store.errors[kind] {
                        Text(error)
                            .font(.system(size: 10.5))
                            .foregroundStyle(Theme.up)
                            .lineLimit(1)
                    } else {
                        Text("成功 \(gmFullDateTime(store.lastSuccess[kind]))")
                            .font(.system(size: 10.5))
                            .monospacedDigit()
                            .foregroundStyle(Theme.muted)
                    }
                }
            }
        }
        .gmCard(padding: 16)
    }
}
