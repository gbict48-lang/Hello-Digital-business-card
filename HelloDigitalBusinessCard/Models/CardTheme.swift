import SwiftUI

/// Visual style of a business card. Kept small and `Codable` so a card can be
/// exported, shared and restored with its look intact.
struct CardTheme: Codable, Hashable {
    enum Style: String, Codable, CaseIterable, Identifiable {
        case gradient      // accent → secondary diagonal gradient
        case solid         // flat accent colour
        case glass         // frosted / liquid-glass look over the accent
        case mono          // near-black, minimal, accent used sparingly

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .gradient: "Gradient"
            case .solid:    "Solid"
            case .glass:    "Liquid Glass"
            case .mono:     "Mono"
            }
        }
    }

    var style: Style
    var accent: RGBAColor
    var secondary: RGBAColor
    /// Whether card text should render light (for dark backgrounds) or dark.
    var prefersLightText: Bool

    static let presets: [CardTheme] = [
        CardTheme(style: .gradient,
                  accent: RGBAColor(hex: "#0A84FF")!,
                  secondary: RGBAColor(hex: "#5E5CE6")!,
                  prefersLightText: true),
        CardTheme(style: .gradient,
                  accent: RGBAColor(hex: "#FF375F")!,
                  secondary: RGBAColor(hex: "#FF9F0A")!,
                  prefersLightText: true),
        CardTheme(style: .glass,
                  accent: RGBAColor(hex: "#30D158")!,
                  secondary: RGBAColor(hex: "#0A84FF")!,
                  prefersLightText: true),
        CardTheme(style: .solid,
                  accent: RGBAColor(hex: "#1C1C1E")!,
                  secondary: RGBAColor(hex: "#2C2C2E")!,
                  prefersLightText: true),
        CardTheme(style: .mono,
                  accent: RGBAColor(hex: "#F2F2F7")!,
                  secondary: RGBAColor(hex: "#8E8E93")!,
                  prefersLightText: false),
        CardTheme(style: .gradient,
                  accent: RGBAColor(hex: "#BF5AF2")!,
                  secondary: RGBAColor(hex: "#0A84FF")!,
                  prefersLightText: true)
    ]

    static let `default` = presets[0]

    var textColor: Color { prefersLightText ? .white : Color(hex: "#1C1C1E") }
    var secondaryTextColor: Color {
        (prefersLightText ? Color.white : Color(hex: "#1C1C1E")).opacity(0.72)
    }
}

extension Color {
    init(hex: String) {
        self = RGBAColor(hex: hex)?.color ?? .accentColor
    }
}
