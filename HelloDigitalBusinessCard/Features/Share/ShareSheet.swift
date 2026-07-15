import SwiftUI
import UIKit

/// Thin wrapper around `UIActivityViewController` for sharing a `.vcf` file,
/// QR image, or a link.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

enum VCardExporter {
    /// Writes a `.vcf` file for the card to a temporary URL so it can be shared
    /// or opened straight into Contacts.
    static func exportFile(for card: BusinessCard) -> URL? {
        let vcard = VCardBuilder.makeVCard(for: card, includePhoto: true)
        let name = card.fullName.isEmpty ? "contact" : card.fullName
            .replacingOccurrences(of: " ", with: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(name).vcf")
        do {
            try vcard.data(using: .utf8)?.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}
