import Foundation
import UIKit

/// Builds the `pass.json` describing an Apple Wallet pass for a business card,
/// plus the images the pass needs. The result is handed to a signing service
/// (`PassSigningClient`) which turns it into a signed `.pkpass`.
///
/// The pass is a *generic* pass showing the person's name/role on the front and
/// a QR code (their vCard) on the back-of-card barcode, so anyone can scan it
/// straight from Wallet and add the contact.
enum PassBuilder {

    struct PassRequest: Encodable {
        let passJson: [String: AnyEncodable]
        let images: [String: String]   // name -> base64 PNG
    }

    /// - Parameters:
    ///   - card: the business card.
    ///   - passTypeIdentifier: your Pass Type ID, e.g. `pass.nl.gbict.hellocard`.
    ///   - teamIdentifier: Apple Developer Team ID.
    static func makeRequest(
        for card: BusinessCard,
        passTypeIdentifier: String,
        teamIdentifier: String
    ) -> PassRequest {
        let accent = card.theme.accent
        let vcard = VCardBuilder.makeVCard(for: card, includePhoto: false)

        var fields: [String: AnyEncodable] = [
            "formatVersion": AnyEncodable(1),
            "passTypeIdentifier": AnyEncodable(passTypeIdentifier),
            "teamIdentifier": AnyEncodable(teamIdentifier),
            "serialNumber": AnyEncodable(card.id.uuidString),
            "organizationName": AnyEncodable(card.company.isEmpty ? "Hello Card" : card.company),
            "description": AnyEncodable("\(card.fullName) — Digital Business Card"),
            "logoText": AnyEncodable(card.fullName),
            "foregroundColor": AnyEncodable(rgbString(for: card.theme.textColorIsLight ? .white : .black)),
            "labelColor": AnyEncodable(rgbString(forHex: accent.hexString)),
            "backgroundColor": AnyEncodable(rgbString(forHex: accent.hexString))
        ]

        // Barcode: the vCard, so Wallet shows a scannable QR on the pass.
        fields["barcodes"] = AnyEncodable([
            [
                "format": "PKBarcodeFormatQR",
                "message": vcard,
                "messageEncoding": "iso-8859-1",
                "altText": card.fullName
            ]
        ])

        // Generic pass structure.
        var generic: [String: AnyEncodable] = [:]
        generic["primaryFields"] = AnyEncodable([
            field(key: "name", label: "NAME", value: card.fullName)
        ])

        var secondary: [[String: String]] = []
        if !card.jobTitle.isEmpty { secondary.append(field(key: "title", label: "ROLE", value: card.jobTitle)) }
        if !card.company.isEmpty { secondary.append(field(key: "company", label: "COMPANY", value: card.company)) }
        if !secondary.isEmpty { generic["secondaryFields"] = AnyEncodable(secondary) }

        var auxiliary: [[String: String]] = []
        if !card.mobile.isEmpty { auxiliary.append(field(key: "mobile", label: "MOBILE", value: card.mobile)) }
        if !card.email.isEmpty { auxiliary.append(field(key: "email", label: "EMAIL", value: card.email)) }
        if !auxiliary.isEmpty { generic["auxiliaryFields"] = AnyEncodable(auxiliary) }

        var back: [[String: String]] = []
        if !card.website.isEmpty { back.append(field(key: "web", label: "Website", value: card.website)) }
        if !card.phone.isEmpty { back.append(field(key: "phone", label: "Phone", value: card.phone)) }
        for social in card.socials where !social.value.isEmpty {
            back.append(field(key: "social_\(social.id.uuidString)", label: social.platform.title, value: social.value))
        }
        if !back.isEmpty { generic["backFields"] = AnyEncodable(back) }

        fields["generic"] = AnyEncodable(generic)

        return PassRequest(passJson: fields, images: makeImages(for: card))
    }

    // MARK: - Images

    /// Wallet requires at least `icon` (29pt) and benefits from `logo`. We render
    /// a simple monogram tile so a pass always has valid artwork even before the
    /// user adds a photo.
    private static func makeImages(for card: BusinessCard) -> [String: String] {
        var images: [String: String] = [:]

        // icon @1x/2x/3x
        if let icon1 = monogram(card, size: 29),
           let icon2 = monogram(card, size: 58),
           let icon3 = monogram(card, size: 87) {
            images["icon.png"] = base64(icon1)
            images["icon@2x.png"] = base64(icon2)
            images["icon@3x.png"] = base64(icon3)
        }

        // logo — use the avatar if present, else the monogram.
        if let data = card.photoData, let logo = UIImage(data: data) {
            images["logo.png"] = base64(resize(logo, to: CGSize(width: 160, height: 50)))
            images["logo@2x.png"] = base64(resize(logo, to: CGSize(width: 320, height: 100)))
        } else if let logo = monogram(card, size: 100) {
            images["logo.png"] = base64(logo)
            images["logo@2x.png"] = base64(logo)
        }

        return images
    }

    private static func monogram(_ card: BusinessCard, size: CGFloat) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size), format: format)
        return renderer.image { ctx in
            card.theme.accent.uiColor.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
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

    private static func base64(_ image: UIImage) -> String {
        (image.pngData() ?? Data()).base64EncodedString()
    }

    // MARK: - Small helpers

    private static func field(key: String, label: String, value: String) -> [String: String] {
        ["key": key, "label": label, "value": value]
    }

    private static func rgbString(forHex hex: String) -> String {
        guard let c = RGBAColor(hex: hex) else { return "rgb(10,132,255)" }
        return "rgb(\(Int(c.red * 255)),\(Int(c.green * 255)),\(Int(c.blue * 255)))"
    }

    private static func rgbString(for color: UIColor) -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return "rgb(\(Int(r * 255)),\(Int(g * 255)),\(Int(b * 255)))"
    }
}

private extension CardTheme {
    var textColorIsLight: Bool { prefersLightText }
}

extension RGBAColor {
    var uiColor: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: opacity)
    }
}

/// Type-erased `Encodable` so we can build the dynamic `pass.json` tree and
/// still serialise it with `JSONEncoder`.
struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void
    init<T: Encodable>(_ value: T) { encodeClosure = value.encode }
    func encode(to encoder: Encoder) throws { try encodeClosure(encoder) }
}
