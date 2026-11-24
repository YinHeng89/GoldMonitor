import Foundation
import SwiftData
import SwiftUI

@MainActor
final class MarketStore: ObservableObject {
    @Published private(set) var quotes: [GoldQuote.Kind: GoldQuote] = [:]
    @Published private(set) var errors: [GoldQuote.Kind: String] = [:]
    @Published private(set) var lastSuccess: [GoldQuote.Kind: Date] = [:]
    @Published private(set) var isRefreshing = false
    @Published var settings: AppSettings {
        didSet {
            settings.save()
            // 只有影响定时器的设置变更才重建定时器。
            // 关通知 / 切外观也重建的话会 cancel 正在进行的刷新，写成 "cancelled" 错误态。
            if settings.autoRefresh != oldValue.autoRefresh ||
                settings.refreshInterval != oldValue.refreshInterval {
                restartTimer()
            }
            if settings.notificationsEnabled && !oldValue.notificationsEnabled {
                Task { try? await notificationService.requestAuthorization() }
            }
        }
    }

    private let container: ModelContainer
    private let icbcService: any ICBCGoldProviding
    private let sinaService: any LondonGoldProviding
    private let fx168Service: any LondonGoldProviding
    private let monitor: PriceMonitorService
    private let notificationService: any Notifying
    private var timerTask: Task<Void, Never>?

    init(
        container: ModelContainer,
        settings: AppSettings = .load(),
        httpClient: any HTTPFetching = URLSessionHTTPClient(),
        notificationService: any Notifying = NotificationService()
    ) {
        self.container = container
        self.settings = settings
        self.icbcService = ICBCGoldService(client: httpClient)
        self.sinaService = SinaLondonGoldService(client: httpClient)
        self.fx168Service = FX168Service(client: httpClient)
        self.notificationService = notificationService
        self.monitor = PriceMonitorService(notifier: notificationService)
    }

    deinit {
        timerTask?.cancel()
    }

    func start() {
        restartTimer()
        Task { await refresh() }
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        async let london = safeFetch(.london)
        async let icbc = safeFetch(.icbc)
        let results = await (london, icbc)
        apply(.london, result: results.0)
        apply(.icbc, result: results.1)
        persistHistory(successes: [results.0, results.1])
        await checkAlerts()
    }

    func enableNotificationsIfNeeded() async {
        guard settings.notificationsEnabled else { return }
        try? await notificationService.requestAuthorization()
    }

    func londonProviderName() -> String {
        switch settings.londonProvider {
        case .sina: return sinaService.sourceName
        case .fx168: return fx168Service.sourceName
        }
    }

    private func safeFetch(_ kind: GoldQuote.Kind) async -> Result<GoldQuote, Error> {
        do {
            switch kind {
            case .london:
                switch settings.londonProvider {
                case .sina: return .success(try await sinaService.fetch())
                case .fx168: return .success(try await fx168Service.fetch())
                }
            case .icbc:
                return .success(try await icbcService.fetch())
            }
        } catch {
            return .failure(error)
        }
    }

    private func apply(_ kind: GoldQuote.Kind, result: Result<GoldQuote, Error>) {
        switch result {
        case .success(let quote):
            quotes[kind] = quote
            lastSuccess[kind] = quote.fetchedAt
            errors[kind] = nil
        case .failure(let error):
            // 主动取消（关闭自动刷新 / 退出应用）不是行情源故障，不写错误态。
            if let urlError = error as? URLError, urlError.code == .cancelled { return }
            if error is CancellationError { return }
            errors[kind] = error.localizedDescription
        }
    }

    private func persistHistory(successes: [Result<GoldQuote, Error>]) {
        let context = container.mainContext
        for result in successes {
            guard case .success(let quote) = result else { continue }
            context.insert(PriceSnapshot(kind: quote.kind, price: quote.price, sourceName: quote.sourceName, timestamp: quote.fetchedAt))
        }
        do {
            try context.save()
            let descriptor = FetchDescriptor<PriceSnapshot>(sortBy: [SortDescriptor(\.timestamp, order: .forward)])
            let all = try context.fetch(descriptor)
            if all.count > 5_000 {
                for snapshot in all.prefix(all.count - 5_000) { context.delete(snapshot) }
                try context.save()
            }
        } catch {
            print("[GoldMonitor] 历史保存失败: \(error.localizedDescription)")
        }
    }

    private func checkAlerts() async {
        let descriptor = FetchDescriptor<PriceAlert>(predicate: #Predicate { $0.enabled })
        let alerts = (try? container.mainContext.fetch(descriptor)) ?? []
        guard !alerts.isEmpty else { return }
        let sent = await monitor.evaluate(quotes: quotes, alerts: alerts)
        if sent > 0 { try? container.mainContext.save() }
    }

    private func restartTimer() {
        timerTask?.cancel()
        guard settings.autoRefresh else { return }
        let nanoseconds = UInt64(max(15, settings.refreshInterval)) * 1_000_000_000
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: nanoseconds)
                guard !Task.isCancelled else { return }
                // 刷新放到独立 Task，避免定时器被取消时连带取消正在进行的网络请求。
                Task { await self?.refresh() }
            }
        }
    }
}
