import Foundation
import Crypto
@_spi(CMS) import X509
import ZIPFoundation

/// Signs and packages a `.pkpass` entirely on-device.
///
/// Steps (per Apple's PassKit spec):
///  1. build `pass.json` + images,
///  2. write `manifest.json` = SHA-1 of every file,
///  3. create a detached CMS/PKCS#7 signature of the manifest with the Pass
///     Type ID certificate (WWDR included as intermediate),
///  4. zip everything into a `.pkpass`.
enum PassSigner {

    static func makePass(for card: BusinessCard, credentials: PassCredentials) throws -> Data {
        var files = PassBuilder.makeFiles(for: card)

        // 2. manifest.json — SHA-1 digest of each file.
        var manifest: [String: String] = [:]
        for (name, data) in files {
            manifest[name] = sha1Hex(data)
        }
        let manifestData = try JSONSerialization.data(withJSONObject: manifest, options: [.sortedKeys])
        files["manifest.json"] = manifestData

        // 3. detached CMS signature of the manifest.
        //
        // `signingTime` is REQUIRED here: without it, swift-certificates signs
        // the content directly with NO signed attributes, and Apple Wallet
        // rejects that ("the pass isn't valid"). Passing a signing time makes it
        // emit the standard CMS signed-attributes form (content-type,
        // message-digest, signing-time) that PassKit expects — matching what
        // `openssl smime -sign` / Apple's `signpass` produce.
        let signature = try CMS.sign(
            manifestData,
            signatureAlgorithm: .sha256WithRSAEncryption,
            additionalIntermediateCertificates: [credentials.wwdr],
            certificate: credentials.certificate,
            privateKey: credentials.privateKey,
            signingTime: Date()
        )
        files["signature"] = Data(signature)

        // 4. zip into a .pkpass.
        return try zip(files)
    }

    // MARK: - Helpers

    private static func sha1Hex(_ data: Data) -> String {
        Insecure.SHA1.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private static func zip(_ files: [String: Data]) throws -> Data {
        let archive = try Archive(data: Data(), accessMode: .create)
        for (name, fileData) in files {
            try archive.addEntry(
                with: name,
                type: .file,
                uncompressedSize: Int64(fileData.count),
                compressionMethod: .deflate
            ) { position, size in
                let start = Int(position)
                return fileData.subdata(in: start ..< start + size)
            }
        }
        guard let data = archive.data else {
            throw WalletError.signingFailed("Could not assemble the pass archive.")
        }
        return data
    }
}
