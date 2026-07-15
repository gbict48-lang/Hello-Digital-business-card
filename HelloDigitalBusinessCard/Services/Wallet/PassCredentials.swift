import Foundation
import X509
import _CryptoExtras

/// The signing material for Wallet passes, loaded from PEM files bundled with
/// the app. These are injected at build time from GitHub secrets, so they are
/// never committed to source and the user never has to configure anything.
///
/// If the files aren't present (e.g. a fork without the secrets), `load()`
/// returns `nil` and the app simply hides the "Add to Wallet" button — QR
/// sharing keeps working.
struct PassCredentials {
    let certificate: Certificate
    let wwdr: Certificate
    let privateKey: Certificate.PrivateKey

    static func load() -> PassCredentials? {
        guard
            let certPEM = bundleString("pass_certificate", "pem"),
            let keyPEM = bundleString("pass_key", "pem"),
            let wwdrPEM = bundleString("wwdr", "pem")
        else { return nil }

        do {
            let certificate = try Certificate(pemEncoded: certPEM)
            let wwdr = try Certificate(pemEncoded: wwdrPEM)
            let rsaKey = try _RSA.Signing.PrivateKey(pemRepresentation: keyPEM)
            return PassCredentials(
                certificate: certificate,
                wwdr: wwdr,
                privateKey: Certificate.PrivateKey(rsaKey)
            )
        } catch {
            return nil
        }
    }

    private static func bundleString(_ name: String, _ ext: String) -> String? {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext),
              let string = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }
        return string
    }
}
