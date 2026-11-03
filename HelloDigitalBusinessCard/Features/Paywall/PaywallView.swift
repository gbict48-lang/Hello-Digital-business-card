import SwiftUI
import StoreKit

/// The Pro upgrade screen. First card is free; Pro unlocks unlimited cards.
struct PaywallView: View {
    @Environment(StoreManager.self) private var store
    @Environment(\.dismiss) private var dismiss

    private let perks: [(String, String, String)] = [
        ("rectangle.stack.badge.plus", "Unlimited cards", "A card for every role, company or language — add colleagues too."),
        ("building.2.crop.circle", "Your company logo", "Add your brand to the card and the Apple Wallet pass."),
        ("paintpalette.fill", "Every design", "All templates, colours and Liquid Glass styles."),
        ("wallet.pass.fill", "Wallet & sharing", "Add every card to Apple Wallet with unlimited QR shares."),
        ("bolt.heart.fill", "One-time, yours forever", "No subscription. Pay once — restores on all your devices.")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header

                    VStack(spacing: 14) {
                        ForEach(perks, id: \.0) { perk in
                            HStack(spacing: 14) {
                                Image(systemName: perk.0)
                                    .font(.title3)
                                    .foregroundStyle(.tint)
                                    .frame(width: 34)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(perk.1).font(.headline)
                                    Text(perk.2).font(.subheadline).foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }
                    }
                    .padding(20)
                    .glassCard(cornerRadius: 22)
                    .padding(.horizontal, 20)

                    buyButton

                    Button("Restore purchases") {
                        Task { await store.restore(); if store.isPro { dismiss() } }
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                    if let error = store.errorMessage {
                        Text(error).font(.footnote).foregroundStyle(.red).multilineTextAlignment(.center).padding(.horizontal, 24)
                    }

                    Text("A one-time purchase, tied to your Apple ID — it restores automatically on all your devices. No subscription.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 24)
                }
                .padding(.top, 10)
            }
            .background(BackdropView())
            .navigationTitle("Hello Card Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not now") { dismiss() }
                }
            }
            .onChange(of: store.isPro) { _, pro in if pro { dismiss() } }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)
            Text("Unlock everything")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
            Text("Your first card is free. Go Pro for unlimited cards and every design.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private var buyButton: some View {
        Button {
            Task { await store.purchasePro() }
        } label: {
            if store.isPurchasing {
                ProgressView().tint(.white)
            } else {
                VStack(spacing: 2) {
                    Text("Go Pro")
                    if !store.displayPrice.isEmpty {
                        Text("\(store.displayPrice) · one-time").font(.caption).opacity(0.9)
                    }
                }
            }
        }
        .buttonStyle(GlassButtonStyle(prominent: true))
        .disabled(store.isPurchasing)
        .padding(.horizontal, 30)
    }
}
