import AuthenticationServices
import Observation
import SwiftUI

/// Handles Sign in with Apple and remembers onboarding state.
///
/// Signing in is optional — the app is fully usable without an account — but it
/// lets us greet the user and pre-fill their first card with the name Apple
/// provides. No password, no backend: Apple manages the identity.
@Observable
@MainActor
final class AuthManager {
    enum State {
        case unknown       // still checking on launch
        case signedOut
        case signedIn
    }

    private(set) var state: State = .unknown
    private(set) var userID: String?
    private(set) var fullName: String?
    private(set) var email: String?

    var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Keys.onboarded) }
    }

    @ObservationIgnored private let defaults = UserDefaults.standard

    private enum Keys {
        static let onboarded = "hasCompletedOnboarding"
        static let userID = "appleUserID"
        static let fullName = "appleFullName"
        static let email = "appleEmail"
    }

    init() {
        hasCompletedOnboarding = defaults.bool(forKey: Keys.onboarded)
        userID = defaults.string(forKey: Keys.userID)
        fullName = defaults.string(forKey: Keys.fullName)
        email = defaults.string(forKey: Keys.email)
        refreshCredentialState()
    }

    /// On launch, confirm the stored Apple ID is still authorised.
    func refreshCredentialState() {
        guard let userID else {
            state = .signedOut
            return
        }
        ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userID) { [weak self] credentialState, _ in
            Task { @MainActor in
                guard let self else { return }
                switch credentialState {
                case .authorized:
                    self.state = .signedIn
                case .revoked, .notFound, .transferred:
                    self.clear()
                @unknown default:
                    self.state = .signedOut
                }
            }
        }
    }

    /// Called from `SignInWithAppleButton`'s completion handler.
    func handle(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                state = .signedOut
                return
            }
            userID = credential.user
            defaults.set(credential.user, forKey: Keys.userID)

            // Name & email are only delivered on the very first authorisation,
            // so persist them when present and keep the old values otherwise.
            if let name = credential.fullName {
                let formatter = PersonNameComponentsFormatter()
                let full = formatter.string(from: name).trimmingCharacters(in: .whitespaces)
                if !full.isEmpty {
                    fullName = full
                    defaults.set(full, forKey: Keys.fullName)
                }
            }
            if let email = credential.email {
                self.email = email
                defaults.set(email, forKey: Keys.email)
            }
            state = .signedIn

        case .failure:
            // User cancelled or an error occurred — stay signed out, no fuss.
            state = .signedOut
        }
    }

    func signOut() { clear() }

    func completeOnboarding() { hasCompletedOnboarding = true }

    private func clear() {
        userID = nil
        fullName = nil
        email = nil
        defaults.removeObject(forKey: Keys.userID)
        defaults.removeObject(forKey: Keys.fullName)
        defaults.removeObject(forKey: Keys.email)
        state = .signedOut
    }

    /// A blank card pre-filled with whatever we learned from Apple.
    func prefilledCard() -> BusinessCard {
        var card = BusinessCard(theme: .default)
        if let fullName {
            let parts = fullName.split(separator: " ", maxSplits: 1).map(String.init)
            card.firstName = parts.first ?? ""
            card.lastName = parts.count > 1 ? parts[1] : ""
        }
        if let email { card.email = email }
        return card
    }
}
