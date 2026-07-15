import Foundation
import PassKit
import Observation

enum WalletError: LocalizedError {
    case walletUnavailable
    case notSupportedInBuild
    case signingFailed(String)
    case invalidPass

    var errorDescription: String? {
        switch self {
        case .walletUnavailable:
            "Apple Wallet isn't available on this device."
        case .notSupportedInBuild:
            "Wallet passes aren't enabled in this build."
        case .signingFailed(let message):
            "Couldn't create the Wallet pass: \(message)"
        case .invalidPass:
            "The generated pass was invalid."
        }
    }
}

/// Creates and signs a Wallet pass for a card, on-device, ready to present with
/// `PKAddPassesViewController` (see `AddPassesView`).
@Observable
@MainActor
final class WalletService {
    enum State: Equatable {
        case idle
        case working
        case ready
        case failed(String)
    }

    private(set) var state: State = .idle
    private(set) var preparedPass: PKPass?

    /// Loaded once. Nil when the build has no signing certificate bundled.
    @ObservationIgnored private let credentials = PassCredentials.load()

    /// Whether the "Add to Wallet" button should be offered at all.
    var canAddToWallet: Bool {
        PKPassLibrary.isPassLibraryAvailable() && credentials != nil
    }

    func preparePass(for card: BusinessCard) async {
        guard PKPassLibrary.isPassLibraryAvailable() else {
            state = .failed(WalletError.walletUnavailable.localizedDescription)
            return
        }
        guard let credentials else {
            state = .failed(WalletError.notSupportedInBuild.localizedDescription)
            return
        }

        state = .working
        preparedPass = nil
        do {
            // Signing is CPU-bound — keep it off the main actor.
            let data = try await Task.detached(priority: .userInitiated) {
                try PassSigner.makePass(for: card, credentials: credentials)
            }.value
            preparedPass = try PKPass(data: data)
            state = .ready
        } catch let error as WalletError {
            state = .failed(error.localizedDescription)
        } catch {
            state = .failed(WalletError.signingFailed(error.localizedDescription).localizedDescription)
        }
    }

    func reset() {
        state = .idle
        preparedPass = nil
    }
}
