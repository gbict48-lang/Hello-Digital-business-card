import SwiftUI

struct RootView: View {
    @Environment(CardStore.self) private var store
    @State private var editorCard: BusinessCard?
    @State private var isCreatingNew = false
    @State private var showsSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if store.cards.isEmpty {
                    EmptyStateView { startNewCard() }
                } else {
                    CardListView(onEdit: openEditor)
                }
            }
            .navigationTitle("My Cards")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showsSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { startNewCard() } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(item: $editorCard) { card in
            CardEditorView(card: card, isNew: isCreatingNew)
        }
        .sheet(isPresented: $showsSettings) {
            SettingsView()
        }
    }

    private func startNewCard() {
        isCreatingNew = true
        editorCard = BusinessCard(theme: .default)
    }

    private func openEditor(_ card: BusinessCard) {
        isCreatingNew = false
        editorCard = card
    }
}

private struct EmptyStateView: View {
    var onCreate: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "person.crop.rectangle.stack")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)
            VStack(spacing: 8) {
                Text("Create your first card")
                    .font(.title2.weight(.semibold))
                Text("Design a digital business card, share it with a QR code, and add it to Apple Wallet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            Button(action: onCreate) {
                Label("New Card", systemImage: "plus")
            }
            .buttonStyle(GlassButtonStyle(prominent: true))
            .padding(.horizontal, 60)
            Spacer()
        }
    }
}
