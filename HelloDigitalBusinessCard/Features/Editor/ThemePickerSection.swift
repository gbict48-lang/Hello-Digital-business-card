import SwiftUI

/// Design picker: choose a template (shown as a live mini-preview of *your*
/// card), pick a colour preset, or fine-tune the two colours.
struct ThemePickerSection: View {
    @Binding var card: BusinessCard

    var body: some View {
        Section("Design") {
            templates
                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))

            presetsRow
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))

            ColorPicker("Accent colour", selection: Binding(
                get: { card.theme.accent.color },
                set: { card.theme.accent = RGBAColor($0) }
            ))
            ColorPicker("Secondary colour", selection: Binding(
                get: { card.theme.secondary.color },
                set: { card.theme.secondary = RGBAColor($0) }
            ))
        }
    }

    // MARK: - Templates

    private var templates: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(CardTheme.Style.allCases) { style in
                    Button {
                        withAnimation(.snappy) { card.theme.style = style }
                    } label: {
                        VStack(spacing: 7) {
                            BusinessCardView(card: preview(style))
                                .frame(width: 152)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                                        .strokeBorder(Color.accentColor,
                                                      lineWidth: card.theme.style == style ? 3 : 0)
                                )
                            Text(style.displayName)
                                .font(.caption2.weight(card.theme.style == style ? .semibold : .regular))
                                .foregroundStyle(card.theme.style == style ? Color.primary : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func preview(_ style: CardTheme.Style) -> BusinessCard {
        var copy = card
        copy.theme.style = style
        return copy
    }

    // MARK: - Colour presets

    private var presetsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(CardTheme.presets.enumerated()), id: \.offset) { _, preset in
                    Button {
                        withAnimation(.snappy) {
                            card.theme.style = preset.style
                            card.theme.accent = preset.accent
                            card.theme.secondary = preset.secondary
                        }
                    } label: {
                        Circle()
                            .fill(LinearGradient(colors: [preset.accent.color, preset.secondary.color],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 34, height: 34)
                            .overlay(Circle().strokeBorder(.white.opacity(0.5), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }
}
