import Foundation
import UIKit

/// Builds the raw files that make up an Apple Wallet pass for a business card:
/// `pass.json` plus the required images. These are signed & zipped by
/// `PassSigner` into a `.pkpass` entirely on-device — no server involved.
///
/// The pass is a *generic* pass showing the person's name/role, with the vCard
/// encoded as a QR barcode so anyone can scan it from Wallet and save the
/// contact.
enum PassBuilder {

    /// Returns the pass files keyed by their in-package filename.
    static func makeFiles(for card: BusinessCard) -> [String: Data] {
        var files: [String: Data] = [:]

        if let passJSON = try? JSONSerialization.data(
            withJSONObject: passDictionary(for: card),
            options: [.sortedKeys]
        ) {
            files["pass.json"] = passJSON
        }

        for (name, image) in makeImages(for: card) {
            if let png = image.pngData() { files[name] = png }
        }

        return files
    }

    // MARK: - pass.json

    private static func passDictionary(for card: BusinessCard) -> [String: Any] {
        let accent = card.theme.accent

        var dict: [String: Any] = [
            "formatVersion": 1,
            "passTypeIdentifier": PassConstants.passTypeIdentifier,
            "teamIdentifier": PassConstants.teamIdentifier,
            "serialNumber": card.id.uuidString,
            "organizationName": card.company.isEmpty ? PassConstants.organizationName : card.company,
            "description": "\(card.fullName) — Digital Business Card",
            "logoText": card.fullName,
            "foregroundColor": "rgb(255, 255, 255)",
            "labelColor": rgb(from: accent),
            "backgroundColor": rgb(from: accent),
            "barcodes": [
                [
                    "format": "PKBarcodeFormatQR",
                    "message": VCardBuilder.makeVCard(for: card, includePhoto: false),
                    "messageEncoding": "iso-8859-1",
                    "altText": card.fullName
                ]
            ]
        ]

        var generic: [String: Any] = [
            "primaryFields": [field("name", "NAME", card.fullName)]
        ]

        var secondary: [[String: String]] = []
        if !card.jobTitle.isEmpty { secondary.append(field("title", "ROLE", card.jobTitle)) }
        if !card.company.isEmpty { secondary.append(field("company", "COMPANY", card.company)) }
        if !secondary.isEmpty { generic["secondaryFields"] = secondary }

        var auxiliary: [[String: String]] = []
        if !card.mobile.isEmpty { auxiliary.append(field("mobile", "MOBILE", card.mobile)) }
        if !card.email.isEmpty { auxiliary.append(field("email", "EMAIL", card.email)) }
        if !auxiliary.isEmpty { generic["auxiliaryFields"] = auxiliary }

        var back: [[String: String]] = []
        if !card.website.isEmpty { back.append(field("web", "Website", card.website)) }
        if !card.phone.isEmpty { back.append(field("phone", "Phone", card.phone)) }
        for social in card.socials where !social.value.isEmpty {
            back.append(field("social_\(social.id.uuidString)", social.platform.title, social.value))
        }
        if !back.isEmpty { generic["backFields"] = back }

        dict["generic"] = generic
        return dict
    }

    // MARK: - Images

    private static func makeImages(for card: BusinessCard) -> [String: UIImage] {
        var images: [String: UIImage] = [:]

        if let i1 = monogram(card, size: 29) { images["icon.png"] = i1 }
        if let i2 = monogram(card, size: 58) { images["icon@2x.png"] = i2 }
        if let i3 = monogram(card, size: 87) { images["icon@3x.png"] = i3 }

        if let data = card.photoData, let logo = UIImage(data: data) {
            images["logo.png"] = resize(logo, to: CGSize(width: 160, height: 50))
            images["logo@2x.png"] = resize(logo, to: CGSize(width: 320, height: 100))
        } else if let logo = monogram(card, size: 90) {
            images["logo.png"] = logo
            images["logo@2x.png"] = logo
        }

        return images
    }

    private static func monogram(_ card: BusinessCard, size: CGFloat) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size), format: format)
        return renderer.image { _ in
            card.theme.accent.uiColor.setFill()
            UIRectFill(CGRect(x: 0, y: 0, width: size, height: size))
            let text = card.initials as NSString
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: size * 0.42, weight: .semibold),
                .foregroundColor: UIColor.white
            ]
            let textSize = text.size(withAttributes: attrs)
            text.draw(
                at: CGPoint(x: (size - textSize.width) / 2, y: (size - textSize.height) / 2),
                withAttributes: attrs
            )
        }
    }

    private static func resize(_ image: UIImage, to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
    }

    // MARK: - Helpers

    private static func field(_ key: String, _ label: String, _ value: String) -> [String: String] {
        ["key": key, "label": label, "value": value]
    }

    private static func rgb(from color: RGBAColor) -> String {
        "rgb(\(Int(color.red * 255)), \(Int(color.green * 255)), \(Int(color.blue * 255)))"
    }
}
