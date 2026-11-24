import SwiftUI
import SwiftData

@main
struct GoldMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store: MarketStore
    private let container: ModelContainer

    init() {
        let container: ModelContainer
        do {
            container = try ModelContainer(for: PriceSnapshot.self, PriceAlert.self, GoldHolding.self)
        } catch {
            fatalError("SwiftData 容器创建失败: \(error.localizedDescription)")
        }
        self.container = container
        self._store = StateObject(wrappedValue: MarketStore(container: container))
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .environmentObject(store)
                .modelContainer(container)
                .frame(minWidth: 960, minHeight: 660)
        }
        .defaultSize(width: 1120, height: 780)
        .windowStyle(.titleBar)

        MenuBarExtra {
            MenuBarView()
                .environmentObject(store)
                .modelContainer(container)
        } label: {
            Label {
                Text("Au \(gmNumber(store.quotes[.london]?.price)) · 积 \(gmNumber(store.quotes[.icbc]?.price))")
            } icon: {
                Image(systemName: "banknote")
            }
        }
        .menuBarExtraStyle(.menu)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
    }
}
