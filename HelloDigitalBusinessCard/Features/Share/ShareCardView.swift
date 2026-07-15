import SwiftUI

/// Full-screen "scan me" view: a large QR of the card's vCard. Anyone scanning
/// it with the Camera app is offered to create a contact immediately.
struct ShareCardView: View {
    @Environment(\.dismiss) private var dismiss
    let card: BusinessCard

    @State private var previousBrightness: CGFloat = UIScreen.main.brightness

    private var vcard: String { VCardBuilder.makeVCard(for: card, includePhoto: false) }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [card.theme.accent.color, card.theme.secondary.color],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                VStack(spacing: 6) {
                    Text(card.fullName)
                        .font(.system(.title, design: .rounded, weight: .bold))
                    if !card.displayTitle.isEmpty {
                        Text(card.displayTitle)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

                QRCodeView(payload: vcard)
                    .frame(width: 260, height: 260)
                    .padding(24)
                    .background(.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .shadow(radius: 20, y: 10)

                Text("Scan with the Camera app to save my contact")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()

                Button { dismiss() } label: {
                    Text("Done").frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle(prominent: true))
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            }
            .padding(.top, 40)
        }
        .onAppear {
            previousBrightness = UIScreen.main.brightness
            UIScreen.main.brightness = 1.0        // brightest for easy scanning
        }
        .onDisappear {
            UIScreen.main.brightness = previousBrightness
        }
    }
}
