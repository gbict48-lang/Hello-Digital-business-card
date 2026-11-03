import SwiftUI

/// Shows a live preview of the Wallet pass, lets the user pick a colour preset,
/// and adds it to Apple Wallet — so what they see is what they get.
struct WalletPreviewSheet: View {
    @Environment(CardStore.self) private var store
    @Environment(StoreManager.self) private var purchases
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
                        WalletPassPreview(card: card, showBranding: !purchases.isPro)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        Text("This is exactly how your card looks in Apple Wallet. To change the colour or logo, edit the card.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)

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

    // MARK: - Add button

    private func addBar(_ card: BusinessCard) -> some View {
        VStack(spacing: 6) {
            Button {
                Task { await wallet.preparePass(for: card, showBranding: !purchases.isPro) }
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
