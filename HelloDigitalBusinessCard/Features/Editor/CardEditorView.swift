import SwiftUI

/// Create / edit a card with a live preview that updates as you type.
struct CardEditorView: View {
    @Environment(CardStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var draft: BusinessCard
    private let isNew: Bool

    init(card: BusinessCard, isNew: Bool) {
        _draft = State(initialValue: card)
        self.isNew = isNew
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    BusinessCardView(card: draft)
                        .padding(.vertical, 8)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                Section("Photo") {
                    HStack {
                        PhotoPickerButton(photoData: $draft.photoData)
                        if draft.photoData != nil {
                            Spacer()
                            Button(role: .destructive) { draft.photoData = nil } label: {
                                Text("Remove")
                            }
                        }
                    }
                }

                Section("Identity") {
                    LabeledField("First name", text: $draft.firstName, icon: "person")
                    LabeledField("Last name", text: $draft.lastName, icon: "person")
                    LabeledField("Job title", text: $draft.jobTitle, icon: "briefcase")
                    LabeledField("Company", text: $draft.company, icon: "building.2")
                    LabeledField("Department", text: $draft.department, icon: "square.grid.2x2")
                }

                Section("Contact") {
                    LabeledField("Phone", text: $draft.phone, icon: "phone", keyboard: .phonePad)
                    LabeledField("Mobile", text: $draft.mobile, icon: "iphone", keyboard: .phonePad)
                    LabeledField("Email", text: $draft.email, icon: "envelope", keyboard: .emailAddress)
                    LabeledField("Website", text: $draft.website, icon: "globe", keyboard: .URL)
                }

                Section("Address") {
                    LabeledField("Street", text: $draft.street, icon: "mappin.and.ellipse")
                    LabeledField("City", text: $draft.city, icon: "building")
                    LabeledField("Postal code", text: $draft.postalCode, icon: "number")
                    LabeledField("Country", text: $draft.country, icon: "flag")
                }

                SocialLinksSection(socials: $draft.socials)

                Section("Notes") {
                    TextField("Anything else…", text: $draft.notes, axis: .vertical)
                        .lineLimit(2...5)
                }

                ThemePickerSection(card: $draft)
            }
            .navigationTitle(isNew ? "New Card" : "Edit Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!draft.hasContent)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        // `update` inserts the card if its id isn't in the store yet, so this
        // correctly handles both new and existing cards without relying on the
        // (cosmetic) `isNew` flag.
        store.update(draft)
        dismiss()
    }
}

private struct LabeledField: View {
    let title: String
    @Binding var text: String
    var icon: String
    var keyboard: UIKeyboardType = .default

    init(_ title: String, text: Binding<String>, icon: String, keyboard: UIKeyboardType = .default) {
        self.title = title
        self._text = text
        self.icon = icon
        self.keyboard = keyboard
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.tint)
                .frame(width: 22)
            TextField(title, text: $text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(keyboard == .emailAddress || keyboard == .URL ? .never : .words)
                .autocorrectionDisabled(keyboard == .emailAddress || keyboard == .URL)
        }
    }
}
