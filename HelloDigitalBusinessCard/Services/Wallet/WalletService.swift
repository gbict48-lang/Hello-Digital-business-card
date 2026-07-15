import Foundation
import PassKit
import Observation

/// High-level entry point the UI uses to add a card to Apple Wallet.
@Observable
@MainActor
final class WalletService {
    enum State: Equatable {
        case idle
        case working
        case ready          // a signed pass is ready to present
        case failed(String)
    }

    private(set) var state: State = .idle
    private(set) var preparedPass: PKPass?

    var isWalletAvailable: Bool { PKPassLibrary.isPassLibraryAvailable() }
    var isConfigured: Bool { WalletConfig.isWalletConfigured }

    /// Builds and signs a pass for the card, ready to be presented with
    /// `PKAddPassesViewController` (see `AddPassesView`).
    func preparePass(for card: BusinessCard) async {
        guard isWalletAvailable else {
            state = .failed(WalletError.walletUnavailable.localizedDescription)
            return
        }
        guard let baseURL = WalletConfig.signingBaseURL else {
            state = .failed(WalletError.notConfigured.localizedDescription)
            return
        }

        state = .working
        preparedPass = nil
        do {
            let client = PassSigningClient(baseURL: baseURL)
            let pass = try await client.signedPass(for: card)
            preparedPass = pass
            state = .ready
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func reset() {
        state = .idle
        preparedPass = nil
    }
}
