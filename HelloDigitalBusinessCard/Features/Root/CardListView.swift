import SwiftUI

/// Home screen: a wallet-style stack of the user's cards. Tapping opens detail.
struct CardListView: View {
    @Environment(CardStore.self) private var store
    var onEdit: (BusinessCard) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 18) {
                ForEach(store.cards) { card in
                    NavigationLink {
                        CardDetailView(cardID: card.id, onEdit: onEdit)
                    } label: {
                        BusinessCardView(card: card, showsQRHint: true)
                            .overlay(alignment: .topTrailing) {
                                if store.primaryCardID == card.id {
                                    PrimaryBadge()
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button { onEdit(card) } label: { Label("Edit", systemImage: "pencil") }
                        Button { store.makePrimary(card) } label: {
                            Label("Set as Primary", systemImage: "star")
                        }
                        Button(role: .destructive) { store.delete(card) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
        .background(BackdropView())
    }
}

private struct PrimaryBadge: View {
    var body: some View {
        Label("Primary", systemImage: "star.fill")
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(.white)
            .glassCard(cornerRadius: 20)
            .padding(12)
    }
}

/// Soft ambient background so glass surfaces have something to refract.
struct BackdropView: View {
    var body: some View {
        LinearGradient(
            colors: [Color(hex: "#0A84FF").opacity(0.10), Color(hex: "#BF5AF2").opacity(0.08)],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
