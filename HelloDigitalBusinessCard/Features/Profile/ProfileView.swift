import SwiftUI
import AuthenticationServices

/// Account & about. No app configuration here — the app is designed to just work.
struct ProfileView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            List {
                Section {
                    accountRow
                        .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                }

                if auth.state == .signedIn {
                    Section {
                        Button(role: .destructive) { auth.signOut() } label: {
                            Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }
                }

                Section {
                    LabeledContent("Version", value: appVersion)
                    Link(destination: URL(string: "https://gbict.nl")!) {
                        Label("Made by GB ICT", systemImage: "globe")
                    }
                } footer: {
                    Text("Hello Digital Business Card is free. Your cards are stored on your device.")
                }
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private var accountRow: some View {
        if auth.state == .signedIn {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(Color.accentColor.gradient).frame(width: 56, height: 56)
                    Text(initials)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(auth.fullName ?? "Signed in")
                        .font(.headline)
                    if let email = auth.email {
                        Text(email).font(.subheadline).foregroundStyle(.secondary)
                    }
                    Label("Signed in with Apple", systemImage: "apple.logo")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text("Sign in to personalise your cards")
                    .font(.headline)
                Text("Optional — the app works fully without an account.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    auth.handle(result)
                }
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 48)
                .clipShape(Capsule())
            }
        }
    }

    private var initials: String {
        guard let name = auth.fullName else { return "" }
        let parts = name.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last = parts.count > 1 ? (parts.last?.first.map(String.init) ?? "") : ""
        return (first + last).uppercased()
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}
