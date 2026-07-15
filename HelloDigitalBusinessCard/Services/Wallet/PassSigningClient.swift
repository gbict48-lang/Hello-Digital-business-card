import Foundation
import PassKit

enum WalletError: LocalizedError {
    case notConfigured
    case walletUnavailable
    case signingFailed(String)
    case invalidPass

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            "Apple Wallet isn't set up yet. Add your pass-signing endpoint in Settings."
        case .walletUnavailable:
            "Apple Wallet isn't available on this device."
        case .signingFailed(let message):
            "Couldn't create the Wallet pass: \(message)"
        case .invalidPass:
            "The signing service returned an invalid pass."
        }
    }
}

/// Talks to the backend that signs passes. Sends the built `pass.json` + images
/// and receives a signed `.pkpass` back.
struct PassSigningClient {
    var baseURL: URL

    /// Requests a signed pass for the given card.
    func signedPass(for card: BusinessCard) async throws -> PKPass {
        let request = PassBuilder.makeRequest(
            for: card,
            passTypeIdentifier: WalletConfig.passTypeIdentifier,
            teamIdentifier: WalletConfig.teamIdentifier
        )

        var urlRequest = URLRequest(url: baseURL.appendingPathComponent("generate-pass"))
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/vnd.apple.pkpass", forHTTPHeaderField: "Accept")

        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: urlRequest)
        } catch {
            throw WalletError.signingFailed(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw WalletError.signingFailed("No response from signing service.")
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw WalletError.signingFailed(body)
        }

        do {
            return try PKPass(data: data)
        } catch {
            throw WalletError.invalidPass
        }
    }
}
