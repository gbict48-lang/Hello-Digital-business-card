import SwiftUI

struct CardDetailView: View {
    @Environment(CardStore.self) private var store
    let cardID: UUID
    var onEdit: (BusinessCard) -> Void

    @State private var wallet = WalletService()
    @State private var showsQR = false
    @State private var showsShareSheet = false
    @State private var showsAddPass = false
    @State private var shareItems: [Any] = []

    private var card: BusinessCard? { store.cards.first { $0.id == cardID } }

    var body: some View {
        ScrollView {
            if let card {
                VStack(spacing: 24) {
                    BusinessCardView(card: card, showsQRHint: true)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                    actions(for: card)

                    QuickContactList(card: card)
                }
                .padding(.bottom, 40)
            } else {
                ContentUnavailableView("Card not found", systemImage: "questionmark.folder")
            }
        }
        .background(BackdropView())
        .navigationTitle(card?.fullName ?? "Card")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let card {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button { onEdit(card) } label: { Label("Edit", systemImage: "pencil") }
                        Button { store.makePrimary(card) } label: { Label("Set as Primary", systemImage: "star") }
                        Button { exportVCard(card) } label: { Label("Export .vcf", systemImage: "square.and.arrow.up") }
                        Divider()
                        Button(role: .destructive) { store.delete(card) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showsQR) {
            if let card { ShareCardView(card: card) }
        }
        .sheet(isPresented: $showsShareSheet) {
            ShareSheet(items: shareItems)
        }
        .fullScreenCover(isPresented: $showsAddPass) {
            if let pass = wallet.preparedPass {
                AddPassesView(pass: pass) { _ in
                    showsAddPass = false
                    wallet.reset()
                }
                .ignoresSafeArea()
            }
        }
        .onChange(of: wallet.state) { _, state in
            if state == .ready { showsAddPass = true }
        }
    }

    // MARK: - Actions

    @ViewBuilder
    private func actions(for card: BusinessCard) -> some View {
        VStack(spacing: 12) {
            Button { showsQR = true } label: {
                Label("Share via QR", systemImage: "qrcode")
            }
            .buttonStyle(GlassButtonStyle(prominent: true))

            HStack(spacing: 12) {
                if wallet.canAddToWallet {
                    Button {
                        Task { await wallet.preparePass(for: card) }
                    } label: {
                        if wallet.state == .working {
                            ProgressView()
                        } else {
                            Label("Apple Wallet", systemImage: "wallet.pass")
                        }
                    }
                    .buttonStyle(GlassButtonStyle())
                    .disabled(wallet.state == .working)
                }

                Button { exportVCard(card) } label: {
                    Label("Share Card", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(GlassButtonStyle())
            }

            if case .failed(let message) = wallet.state {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, 20)
    }

    private func exportVCard(_ card: BusinessCard) {
        var items: [Any] = []
        if let file = VCardExporter.exportFile(for: card) { items.append(file) }
        if let qr = QRCodeGenerator.vCardImage(for: card) { items.append(qr) }
        shareItems = items
        showsShareSheet = true
    }
}

/// A tappable list of the card's contact rows below the actions.
private struct QuickContactList: View {
    let card: BusinessCard

    var body: some View {
        VStack(spacing: 0) {
            row("phone.fill", "Phone", card.phone, url: "tel:\(digits(card.phone))")
            row("iphone", "Mobile", card.mobile, url: "tel:\(digits(card.mobile))")
            row("envelope.fill", "Email", card.email, url: "mailto:\(card.email)")
            row("globe", "Website", card.website, url: card.website)
            ForEach(card.socials) { social in
                row(social.platform.symbol, social.platform.title, social.value, url: social.value)
            }
        }
        .glassCard(cornerRadius: 24)
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func row(_ icon: String, _ label: String, _ value: String, url: String) -> some View {
        if !value.isEmpty {
            Link(destination: URL(string: url) ?? URL(string: "https://apple.com")!) {
                HStack(spacing: 14) {
                    Image(systemName: icon)
                        .foregroundStyle(.tint)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(label).font(.caption).foregroundStyle(.secondary)
                        Text(value).font(.body).foregroundStyle(.primary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            Divider().padding(.leading, 54)
        }
    }

    private func digits(_ phone: String) -> String {
        phone.filter { $0.isNumber || $0 == "+" }
    }
}
