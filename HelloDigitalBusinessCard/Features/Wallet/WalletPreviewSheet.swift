import SwiftUI

/// Shows a live preview of the Wallet pass, lets the user pick a colour preset,
/// and adds it to Apple Wallet — so what they see is what they get.
struct WalletPreviewSheet: View {
    @Environment(CardStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let cardID: UUID

    @State private var wallet = WalletService()
    @State private var showAddPass = false

    private var card: BusinessCard? { store.cards.first { $0.id == cardID } }

    var body: some View {
        NavigationStack {
            if let card {
                ScrollView {
                    VStack(spacing: 26) {
                        WalletPassPreview(card: card)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        presets(for: card)

                        if case .failed(let message) = wallet.state {
                            Text(message)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                    }
                    .padding(.bottom, 24)
                }
                .background(BackdropView())
                .safeAreaInset(edge: .bottom) { addBar(card) }
            } else {
                ContentUnavailableView("Card not found", systemImage: "questionmark.folder")
            }
        }
        .navigationTitle("Wallet Preview")
        .navigationBarTitleDisplayMode(.inline)
        .presentationDetents([.large])
        .fullScreenCover(isPresented: $showAddPass) {
            if let pass = wallet.preparedPass {
                AddPassesView(pass: pass) { _ in
                    showAddPass = false
                    wallet.reset()
                    dismiss()
                }
                .ignoresSafeArea()
            }
        }
        .onChange(of: wallet.state) { _, state in
            if state == .ready { showAddPass = true }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }

    // MARK: - Colour presets

    private func presets(for card: BusinessCard) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Colour")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(CardTheme.presets.enumerated()), id: \.offset) { _, preset in
                        Button {
                            apply(preset, to: card)
                        } label: {
                            Circle()
                                .fill(preset.accent.color)
                                .frame(width: 38, height: 38)
                                .overlay(
                                    Circle().strokeBorder(
                                        card.theme.accent == preset.accent ? Color.primary : .white.opacity(0.4),
                                        lineWidth: card.theme.accent == preset.accent ? 3 : 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private func apply(_ preset: CardTheme, to card: BusinessCard) {
        var updated = card
        updated.theme.accent = preset.accent
        updated.theme.secondary = preset.secondary
        withAnimation(.snappy) { store.update(updated) }
    }

    // MARK: - Add button

    private func addBar(_ card: BusinessCard) -> some View {
        VStack(spacing: 6) {
            Button {
                Task { await wallet.preparePass(for: card) }
            } label: {
                HStack(spacing: 8) {
                    if wallet.state == .working {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "wallet.pass.fill")
                        Text("Add to Apple Wallet")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(GlassButtonStyle(prominent: true))
            .disabled(wallet.state == .working)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
    }
}
