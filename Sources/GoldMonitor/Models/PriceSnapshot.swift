import Foundation
import SwiftData

@Model
final class PriceSnapshot {
    var kindRaw: String
    var price: Double
    var sourceName: String
    var timestamp: Date

    init(kind: GoldQuote.Kind, price: Double, sourceName: String, timestamp: Date = Date()) {
        self.kindRaw = kind.rawValue
        self.price = price
        self.sourceName = sourceName
        self.timestamp = timestamp
    }

    var kind: GoldQuote.Kind {
        get { GoldQuote.Kind(rawValue: kindRaw) ?? .icbc }
        set { kindRaw = newValue.rawValue }
    }
}

struct AppSettings: Codable, Sendable {
    enum Appearance: String, Codable, Sendable, CaseIterable {
        case dark
        case light
        case system

        var displayName: String {
            switch self {
            case .dark: return "深色"
            case .light: return "浅色"
            case .system: return "跟随系统"
            }
        }
    }

    enum LondonProvider: String, Codable, Sendable, CaseIterable {
        case sina
        case fx168

        var displayName: String {
            switch self {
            case .sina: return "新浪财经 hf_XAU（已验证）"
            case .fx168: return "FX168 网页解析（实验性）"
            }
        }
    }

    var refreshInterval: Int = 60
    var autoRefresh: Bool = true
    var notificationsEnabled: Bool = true
    var appearance: Appearance = .dark
    var londonProvider: LondonProvider = .sina

    static let defaults = AppSettings()

    static func load() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: "goldmonitor.settings"),
              let decoded = try? JSONDecoder().decode(AppSettings.self, from: data)
        else { return .defaults }
        return decoded
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: "goldmonitor.settings")
    }
}
