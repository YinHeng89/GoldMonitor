import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var store: MarketStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Gold Monitor")
                .font(.system(size: 12, weight: .semibold))
            ForEach(GoldQuote.Kind.allCases) { kind in
                HStack(spacing: 6) {
                    Circle()
                        .fill(store.errors[kind] != nil ? Theme.up : Theme.down)
                        .frame(width: 6, height: 6)
                    Text(kind.shortName)
                        .frame(width: 62, alignment: .leading)
                    Text(gmNumber(store.quotes[kind]?.price))
                        .monospacedDigit()
                        .fontWeight(.semibold)
                    Text(kind.unit)
                        .foregroundStyle(.secondary)
                        .font(.system(size: 10))
                }
                .font(.system(size: 11.5))
            }
            Text("更新 \(gmDateTime(store.lastSuccess[.london])) / \(gmDateTime(store.lastSuccess[.icbc]))")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)

            Divider()

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

            Divider()
            Button("退出 Gold Monitor") {
                NSApp.terminate(nil)
            }
        }
    }
}
