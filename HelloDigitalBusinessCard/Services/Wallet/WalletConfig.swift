import Foundation

/// Configuration needed to build & sign Apple Wallet passes.
///
/// The signing endpoint URL is read (in order) from:
///   1. a value the user saved in Settings (`UserDefaults`), then
///   2. the `PassSigningBaseURL` key in Info.plist, then
///   3. `nil` — in which case the "Add to Wallet" button explains setup is needed.
///
/// This keeps the private signing certificate off the device (it lives on the
/// backend) while letting the app stay fully functional for QR sharing.
enum WalletConfig {
    static let teamIdentifier = "476FB5QW34"
    static let passTypeIdentifier = "pass.nl.gbict.hellodigitalbusinesscard"

    private static let signingURLDefaultsKey = "passSigningBaseURL"

    static var signingBaseURL: URL? {
        get {
            if let saved = UserDefaults.standard.string(forKey: signingURLDefaultsKey),
               let url = URL(string: saved), !saved.isEmpty {
                return url
            }
            if let plist = Bundle.main.object(forInfoDictionaryKey: "PassSigningBaseURL") as? String,
               let url = URL(string: plist), !plist.isEmpty {
                return url
            }
            return nil
        }
        set {
            UserDefaults.standard.set(newValue?.absoluteString, forKey: signingURLDefaultsKey)
        }
    }

    static var isWalletConfigured: Bool { signingBaseURL != nil }
}
