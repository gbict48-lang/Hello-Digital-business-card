import SwiftUI

struct ThemePickerSection: View {
    @Binding var theme: CardTheme

    var body: some View {
        Section("Style") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(CardTheme.presets.enumerated()), id: \.offset) { _, preset in
                        Button {
                            theme = preset
                        } label: {
                            swatch(preset)
                                .overlay {
                                    if preset == theme {
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .strokeBorder(Color.accentColor, lineWidth: 3)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

            Picker("Layout", selection: $theme.style) {
                ForEach(CardTheme.Style.allCases) { style in
                    Text(style.displayName).tag(style)
                }
            }

            ColorPicker("Accent colour", selection: Binding(
                get: { theme.accent.color },
                set: { theme.accent = RGBAColor($0) }
            ))
            ColorPicker("Secondary colour", selection: Binding(
                get: { theme.secondary.color },
                set: { theme.secondary = RGBAColor($0) }
            ))
            Toggle("Light text", isOn: $theme.prefersLightText)
        }
    }

    private func swatch(_ preset: CardTheme) -> some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(LinearGradient(
                colors: [preset.accent.color, preset.secondary.color],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
            .frame(width: 64, height: 44)
    }
}
