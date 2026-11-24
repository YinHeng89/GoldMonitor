import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable, Hashable {
    case overview
    case london
    case icbc
    case alerts
    case history
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: return "总览"
        case .london: return "伦敦金"
        case .icbc: return "工行积存金"
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
            List(SidebarItem.allCases, id: \.self, selection: $selection) { item in
                let selected = item == selection
                NavigationLink(value: item) {
                    Label {
                        Text(item.title)
                            .font(.system(size: 13.5, weight: selected ? .semibold : .medium))
                    } icon: {
                        Image(systemName: item.icon)
                            .font(.system(size: 13.5, weight: .semibold))
                    }
                    .foregroundStyle(Theme.gold.opacity(selected ? 1 : 0.72))
                    .padding(.vertical, 5)
                }
                .buttonStyle(.plain)
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(selected ? Theme.gold.opacity(0.12) : Color.clear)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                )
            }
            .listStyle(.sidebar)
            .navigationTitle("Gold Monitor")
            .frame(minWidth: 190)
        } detail: {
            detailView
                .frame(minWidth: 680)
        }
        .navigationSplitViewStyle(.balanced)
        .background(Theme.background)
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
