import Foundation
import SwiftData

enum AlertDirection: String, Codable, Sendable, CaseIterable, Identifiable {
    case above = "高于"
    case below = "低于"

    var id: String { rawValue }
}

@Model
final class PriceAlert {
    var kindRaw: String
    var directionRaw: String
    var target: Double
    var enabled: Bool
    var armed: Bool
    var createdAt: Date
    var lastTriggeredAt: Date?
    var lastTriggeredPrice: Double?

    init(
        kind: GoldQuote.Kind,
        direction: AlertDirection,
        target: Double,
        enabled: Bool = true,
        armed: Bool = true,
        createdAt: Date = Date()
    ) {
        self.kindRaw = kind.rawValue
        self.directionRaw = direction.rawValue
        self.target = target
        self.enabled = enabled
        self.armed = armed
        self.createdAt = createdAt
        self.lastTriggeredAt = nil
        self.lastTriggeredPrice = nil
    }

    var kind: GoldQuote.Kind {
        get { GoldQuote.Kind(rawValue: kindRaw) ?? .icbc }
        set { kindRaw = newValue.rawValue }
    }

    var direction: AlertDirection {
        get { AlertDirection(rawValue: directionRaw) ?? .above }
        set { directionRaw = newValue.rawValue }
    }

    var title: String {
        "\(kind.shortName) \(direction.rawValue) \(Self.format(target, kind: kind)) \(kind.unit)"
    }

    func matches(price: Double) -> Bool {
        switch direction {
        case .above: return price >= target
        case .below: return price <= target
        }
    }

    static func format(_ value: Double, kind: GoldQuote.Kind) -> String {
        String(format: kind == .london ? "%.2f" : "%.2f", value)
    }
}
