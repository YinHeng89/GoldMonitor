import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable, Hashable {
    case overview
    case london
    case icbc
    case holdings
    case alerts
    case history
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: return "总览"
        case .london: return "伦敦金"
        case .icbc: return "工行积存金"
        case .holdings: return "我的持仓"
        case .alerts: return "价格预警"
        case .history: return "历史记录"
        case .settings: return "系统设置"
        }
    }

    var icon: String {
        switch self {
        case .overview: return "square.grid.2x2"
        case .london: return "globe.americas"
        case .icbc: return "banknote"
        case .holdings: return "briefcase"
        case .alerts: return "bell.badge"
        case .history: return "clock.arrow.circlepath"
        case .settings: return "gearshape"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var store: MarketStore
    @State private var selection: SidebarItem? = .overview

    var body: some View {
        NavigationSplitView {
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(SidebarItem.allCases) { item in
                        let selected = item == selection
                        Button {
                            selection = item
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: item.icon)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Theme.gold.opacity(selected ? 1 : 0.85))
                                    .frame(width: 20, alignment: .center)
                                Text(item.title)
                                    .font(.system(size: 13.5, weight: selected ? .semibold : .medium))
                                    .foregroundStyle(.primary)
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(selected ? Theme.gold.opacity(0.16) : Color.clear)
                            }
                            .overlay(alignment: .leading) {
                                if selected {
                                    RoundedRectangle(cornerRadius: 1.5)
                                        .fill(Theme.gold)
                                        .frame(width: 3, height: 18)
                                        .padding(.leading, 4)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .navigationTitle("Gold Monitor")
            .frame(minWidth: 190)
        } detail: {
            detailView
                .frame(minWidth: 680)
        }
        .navigationSplitViewStyle(.balanced)
        .background(Theme.background)
        .tint(Theme.gold)
        .preferredColorScheme(colorScheme)
        .task {
            await store.enableNotificationsIfNeeded()
            store.start()
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch selection {
        case .overview: DashboardView()
        case .london: QuoteDetailView(kind: .london)
        case .icbc: QuoteDetailView(kind: .icbc)
        case .holdings: HoldingsView()
        case .alerts: AlertView()
        case .history: HistoryView()
        case .settings: SettingsView()
        case nil: DashboardView()
        }
    }

    private var colorScheme: ColorScheme? {
        switch store.settings.appearance {
        case .dark: return .dark
        case .light: return .light
        case .system: return nil
        }
    }
}
