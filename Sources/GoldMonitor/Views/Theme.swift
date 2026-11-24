import SwiftUI

enum Theme {
    static let background = adaptive(light: 0xF4F5F7, dark: 0x0B0E13)
    static let panel = adaptive(light: 0xFFFFFF, dark: 0x141922)
    static let panelElevated = adaptive(light: 0xFAFBFC, dark: 0x1B222D)
    static let border = adaptive(light: 0xE1E5EB, dark: 0x27303C)
    static let text = adaptive(light: 0x1B2230, dark: 0xEAEFF5)
    static let secondary = adaptive(light: 0x657084, dark: 0x98A4B4)
    static let muted = adaptive(light: 0x99A2AF, dark: 0x647084)
    static let gold = adaptive(light: 0x9A731A, dark: 0xE8C579)
    static let goldDim = adaptive(light: 0xC6A658, dark: 0x8E7440)
    static let up = adaptive(light: 0xC83636, dark: 0xF06561)
    static let down = adaptive(light: 0x0E8F63, dark: 0x35C38D)
    static let accent = Color.accentColor

    private static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return NSColor(hex: isDark ? dark : light)
        }))
    }

    static func priceColor(_ value: Double?) -> Color {
        guard let value else { return secondary }
        return value > 0 ? up : (value < 0 ? down : secondary)
    }

    static func moveColor(_ move: GoldQuote.PriceMove?) -> Color {
        guard let move else { return secondary }
        return move == .up ? up : (move == .down ? down : secondary)
    }
}

extension NSColor {
    convenience init(hex: UInt32) {
        self.init(
            calibratedRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

struct CardStyle: ViewModifier {
    var padding: CGFloat = 18
    var cornerRadius: CGFloat = 14

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.panel, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Theme.border, lineWidth: 1)
            }
    }
}

extension View {
    func gmCard(padding: CGFloat = 18, radius: CGFloat = 14) -> some View {
        modifier(CardStyle(padding: padding, cornerRadius: radius))
    }
}

func gmNumber(_ value: Double?, digits: Int = 2) -> String {
    guard let value, value.isFinite else { return "--" }
    return String(format: "%.\(digits)f", value)
}

/// 用户输入量（克数、成本价）：最多保留 6 位小数并去掉尾随 0，
/// 不像 gmNumber 固定 2 位那样把 1.3940 显示成 1.39。
func gmAmount(_ value: Double?) -> String {
    guard let value, value.isFinite else { return "--" }
    if value == value.rounded() { return String(format: "%.0f", value) }
    return String(format: "%.6f", value)
        .replacingOccurrences(of: "0+$", with: "", options: .regularExpression)
}

func gmSigned(_ value: Double?, digits: Int = 2) -> String {
    guard let value, value.isFinite else { return "--" }
    return String(format: "%+.\(digits)f", value)
}

func gmPercent(_ value: Double?) -> String {
    guard let value, value.isFinite else { return "--" }
    return String(format: "%+.2f%%", value * 100)
}

func gmDateTime(_ date: Date?) -> String {
    guard let date else { return "尚未获取" }
    let formatter = DateFormatter()
    formatter.dateFormat = "MM-dd HH:mm:ss"
    return formatter.string(from: date)
}

func gmFullDateTime(_ date: Date?) -> String {
    guard let date else { return "尚未获取" }
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return formatter.string(from: date)
}
