import SwiftUI

/// Visual style of a business card. `Codable` so a card can be exported, shared
/// and restored with its look intact.
struct CardTheme: Codable, Hashable {
    enum Style: String, CaseIterable, Identifiable, Hashable {
        case gradient      // vivid accent → secondary diagonal
        case aurora        // soft glowing blobs on a deep base
        case glass         // vivid gradient with a frosted info panel
        case spotlight     // dark card with an accent glow behind the avatar
        case minimal       // light card, dark text, accent details
        case bold          // solid accent with a large monogram watermark

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .gradient:  "Gradient"
            case .aurora:    "Aurora"
            case .glass:     "Liquid Glass"
            case .spotlight: "Spotlight"
            case .minimal:   "Minimal"
            case .bold:      "Bold"
            }
        }

        // Lenient decoding so older saved cards (or future values) never fail
        // to load — anything unknown falls back to `.gradient`.
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let raw = (try? container.decode(String.self)) ?? ""
            self = Style(rawValue: raw) ?? .gradient
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }
    }

    var style: Style
    var accent: RGBAColor
    var secondary: RGBAColor
    /// Retained for backwards compatibility with previously saved cards.
    /// Text colour is now derived automatically for correct contrast.
    var prefersLightText: Bool = true

    // MARK: - Presets (a spread of looks, not just colours)

    static let presets: [CardTheme] = [
        CardTheme(style: .gradient,  accent: hex("#0A84FF"), secondary: hex("#5E5CE6")),
        CardTheme(style: .aurora,    accent: hex("#5E5CE6"), secondary: hex("#FF2D55")),
        CardTheme(style: .glass,     accent: hex("#30D158"), secondary: hex("#0A84FF")),
        CardTheme(style: .spotlight, accent: hex("#0A84FF"), secondary: hex("#64D2FF")),
        CardTheme(style: .bold,      accent: hex("#FF375F"), secondary: hex("#FF9F0A")),
        CardTheme(style: .minimal,   accent: hex("#0A84FF"), secondary: hex("#8E8E93")),
        CardTheme(style: .gradient,  accent: hex("#FF9F0A"), secondary: hex("#FF375F")),
        CardTheme(style: .aurora,    accent: hex("#64D2FF"), secondary: hex("#BF5AF2")),
        CardTheme(style: .bold,      accent: hex("#1C1C1E"), secondary: hex("#3A3A3C"))
    ]

    static let `default` = presets[0]

    private static func hex(_ value: String) -> RGBAColor { RGBAColor(hex: value)! }

    // MARK: - Derived colours (automatic contrast)

    private func luminance(_ c: RGBAColor) -> Double {
        0.299 * c.red + 0.587 * c.green + 0.114 * c.blue
    }

    /// Whether the card surface is light (so it needs dark text).
    var isLightSurface: Bool {
        switch style {
        case .minimal:            true
        case .spotlight, .aurora: false
        case .gradient, .glass, .bold: luminance(accent) > 0.62
        }
    }

    var foreground: Color { isLightSurface ? Color(hex: "#111114") : .white }
    var secondaryForeground: Color { foreground.opacity(0.72) }
}

extension Color {
    init(hex: String) {
        self = RGBAColor(hex: hex)?.color ?? .accentColor
    }
}
