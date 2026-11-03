import SwiftUI

/// The card's chosen **design** (gradient / aurora / spotlight / …) rendered as a
/// full-bleed background, tuned for a dark Wallet pass: always dark enough for
/// white text, with a bottom scrim for field legibility.
///
/// This is the single source of truth for the look of the Wallet pass. The live
/// preview (`WalletPassPreview`) uses it directly, and `WalletArtRenderer`
/// rasterises the exact same view into the `background.png` that ships inside the
/// signed `.pkpass` — so the preview and the real pass can never drift apart.
struct WalletCardBackground: View {
    let card: BusinessCard

    private var theme: CardTheme { card.theme }
    private var accent: Color { theme.accent.color }
    private var secondary: Color { theme.secondary.color }

    var body: some View {
        ZStack {
            design
            // Keep white text + grey labels legible on every preset, and mimic
            // the subtle dimming Wallet applies to pass backgrounds.
            LinearGradient(
                colors: [.black.opacity(0.10), .black.opacity(0.14), .black.opacity(0.52)],
                startPoint: .top, endPoint: .bottom
            )
        }
    }

    @ViewBuilder
    private var design: some View {
        switch theme.style {
        case .gradient:
            LinearGradient(colors: [accent, secondary],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay(RadialGradient(colors: [.white.opacity(0.22), .clear],
                                    center: .topTrailing, startRadius: 4, endRadius: 360))

        case .glass:
            LinearGradient(colors: [accent, secondary],
                           startPoint: .top, endPoint: .bottom)
            .overlay(RadialGradient(colors: [.white.opacity(0.22), .clear],
                                    center: .topLeading, startRadius: 4, endRadius: 320))

        case .aurora:
            ZStack {
                Color(hex: "#0B0B12")
                RadialGradient(colors: [accent.opacity(0.95), .clear],
                               center: .topLeading, startRadius: 0, endRadius: 320)
                RadialGradient(colors: [secondary.opacity(0.9), .clear],
                               center: .bottomTrailing, startRadius: 0, endRadius: 340)
                RadialGradient(colors: [accent.opacity(0.5), .clear],
                               center: UnitPoint(x: 0.8, y: 0.15), startRadius: 0, endRadius: 200)
            }

        case .spotlight:
            ZStack {
                Color(hex: "#0A0A0F")
                RadialGradient(colors: [accent.opacity(0.8), .clear],
                               center: UnitPoint(x: 0.28, y: 0.26), startRadius: 0, endRadius: 300)
                RadialGradient(colors: [secondary.opacity(0.4), .clear],
                               center: .bottomTrailing, startRadius: 0, endRadius: 260)
            }

        case .bold:
            ZStack {
                accent
                LinearGradient(colors: [.white.opacity(0.16), .clear],
                               startPoint: .topLeading, endPoint: .center)
                RadialGradient(colors: [.black.opacity(0.35), .clear],
                               center: .bottomTrailing, startRadius: 0, endRadius: 320)
            }

        case .minimal:
            // Minimal is a light card in-app, but a light Wallet pass can't carry
            // white text — so render a deep, on-brand accent wash instead.
            LinearGradient(colors: [deepen(accent), Color(hex: "#0C0C10")],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    /// A rich, dark jewel version of a colour (keeps hue, caps brightness).
    private func deepen(_ color: Color) -> Color {
        let ui = UIColor(color)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        if s < 0.16 { return Color(uiColor: UIColor(white: 0.16, alpha: 1)) }
        return Color(uiColor: UIColor(hue: h,
                                      saturation: min(max(s, 0.55), 0.9),
                                      brightness: min(b, 0.5), alpha: 1))
    }
}

/// Rasterises `WalletCardBackground` into the pass `background.png` files.
/// `@MainActor` because `ImageRenderer` must run on the main actor.
@MainActor
enum WalletArtRenderer {
    /// Apple's recommended pass background size is 180×220 pt. We emit @1x/@2x/@3x.
    static func backgroundImages(for card: BusinessCard) -> [String: Data] {
        let size = CGSize(width: 180, height: 220)
        var out: [String: Data] = [:]
        for scale in [1, 2, 3] as [CGFloat] {
            let renderer = ImageRenderer(
                content: WalletCardBackground(card: card)
                    .frame(width: size.width, height: size.height)
            )
            renderer.scale = scale
            renderer.isOpaque = true
            if let image = renderer.uiImage, let png = image.pngData() {
                let name = scale == 1 ? "background.png" : "background@\(Int(scale))x.png"
                out[name] = png
            }
        }
        return out
    }
}
