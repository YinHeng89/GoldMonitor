import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: MarketStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("系统设置")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.text)

                VStack(alignment: .leading, spacing: 12) {
                    settingHeader("行情刷新", icon: "timer")
                    Picker("刷新间隔", selection: Binding(
                        get: { store.settings.refreshInterval },
                        set: { store.settings.refreshInterval = $0 }
                    )) {
                        ForEach([15, 30, 60, 120, 300], id: \.self) { second in
                            Text("\(second) 秒").tag(second)
                        }
                    }
                    .pickerStyle(.segmented)
                    Toggle("自动刷新", isOn: Binding(
                        get: { store.settings.autoRefresh },
                        set: { store.settings.autoRefresh = $0 }
                    ))
                    Button {
                        Task { await store.refresh() }
                    } label: {
                        Label("立即测试连接", systemImage: "arrow.triangle.2.circlepath")
                            .font(.system(size: 12))
                    }
                    .disabled(store.isRefreshing)
                }
                .gmCard()

                VStack(alignment: .leading, spacing: 12) {
                    settingHeader("通知与外观", icon: "paintbrush")
                    Toggle("启用系统通知", isOn: Binding(
                        get: { store.settings.notificationsEnabled },
                        set: { store.settings.notificationsEnabled = $0 }
                    ))
                    Button("重新请求通知权限") {
                        Task { await store.enableNotificationsIfNeeded() }
                    }
                    .font(.system(size: 11.5))
                    Picker("外观", selection: Binding(
                        get: { store.settings.appearance },
                        set: { store.settings.appearance = $0 }
                    )) {
                        ForEach(AppSettings.Appearance.allCases, id: \.self) { item in
                            Text(item.displayName).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .gmCard()

                VStack(alignment: .leading, spacing: 12) {
                    settingHeader("数据源", icon: "network")
                    Picker("伦敦金来源", selection: Binding(
                        get: { store.settings.londonProvider },
                        set: { store.settings.londonProvider = $0 }
                    )) {
                        ForEach(AppSettings.LondonProvider.allCases, id: \.self) { item in
                            Text(item.displayName).tag(item)
                        }
                    }
                    Text("FX168 为规划文档指定来源，但当前网络不可达且页面结构可能变化；失败时会明确显示错误，不会把旧数据标为实时。")
                        .font(.system(size: 10.5))
                        .foregroundStyle(Theme.secondary)
                    Divider().background(Theme.border)
                    ForEach(GoldQuote.Kind.allCases) { kind in
                        HStack {
                            StatusBadge(kind: kind)
                            Text(kind.shortName).font(.system(size: 12)).foregroundStyle(Theme.text)
                            Spacer()
                            Text("最后成功 \(gmDateTime(store.lastSuccess[kind]))")
                                .font(.system(size: 10.5))
                                .foregroundStyle(Theme.muted)
                        }
                        if let error = store.errors[kind] {
                            Text(error).font(.system(size: 10.5)).foregroundStyle(Theme.up)
                        }
                    }
                }
                .gmCard()

                VStack(alignment: .leading, spacing: 8) {
                    settingHeader("关于", icon: "info.circle")
                    Text("Gold Monitor for macOS · 原生 SwiftUI 客户端")
                        .font(.system(size: 11.5))
                        .foregroundStyle(Theme.secondary)
                    Text("行情仅供参考，请以交易所与银行官方报价为准。")
                        .font(.system(size: 10.5))
                        .foregroundStyle(Theme.muted)
                }
                .gmCard()
                Spacer(minLength: 10)
            }
            .padding(26)
        }
        .background(Theme.background)
    }

    private func settingHeader(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Theme.gold)
    }
}
