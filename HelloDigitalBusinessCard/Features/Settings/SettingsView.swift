import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var signingURL: String = WalletConfig.signingBaseURL?.absoluteString ?? ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("https://your-signer.vercel.app/api", text: $signingURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                } header: {
                    Text("Apple Wallet signing endpoint")
                } footer: {
                    Text("Passes must be signed with your Pass Type ID certificate on a server. Deploy the included `/server` function and paste its URL here. QR sharing works without this.")
                }

                Section("App Identity") {
                    LabeledContent("Bundle ID", value: "nl.gbict.hellodigitalbusinesscard")
                    LabeledContent("Team ID", value: WalletConfig.teamIdentifier)
                    LabeledContent("Pass Type ID", value: WalletConfig.passTypeIdentifier)
                }

                Section {
                    LabeledContent("Version", value: appVersion)
                } footer: {
                    Text("Hello Digital Business Card — free. Made by GB ICT.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.fontWeight(.semibold)
                }
            }
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    private func save() {
        let trimmed = signingURL.trimmingCharacters(in: .whitespacesAndNewlines)
        WalletConfig.signingBaseURL = trimmed.isEmpty ? nil : URL(string: trimmed)
        dismiss()
    }
}
