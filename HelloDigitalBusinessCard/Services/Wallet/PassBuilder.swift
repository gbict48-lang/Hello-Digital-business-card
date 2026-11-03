import Foundation
import UIKit
import SwiftUI

/// Builds the raw files for an Apple Wallet pass. Signed & zipped on-device by
/// `PassSigner`.
///
/// Follows Apple's Wallet HIG for a premium look: an **eventTicket** pass — the
/// one style that carries a full-bleed **background image**, so the card's chosen
/// design (gradient / aurora / spotlight / …) actually reaches Wallet instead of
/// a flat colour. High-contrast white values + grey labels, the company **logo**
/// top-left, the person photo as a square **thumbnail**, the name as the primary
/// field, a handful of contact fields, and a QR vCard. `WalletPassPreview` and
/// the rendered `background.png` both come from the shared `WalletCardBackground`.
enum PassBuilder {

    /// Small attribution shown under the QR on free passes; removed for Pro.
    static let brandingText = "Made with Hello Digital Business Card"

    /// `backgroundImages` are the rasterised design (`background.png`, `@2x`, `@3x`),
    /// rendered on the main actor by `WalletArtRenderer` and passed in here.
    /// `showBranding` adds the subtle "Made with…" line for free users.
    static func makeFiles(for card: BusinessCard,
                          backgroundImages: [String: Data] = [:],
                          showBranding: Bool = true) -> [String: Data] {
        var files: [String: Data] = [:]
        if let passJSON = try? JSONSerialization.data(
            withJSONObject: passDictionary(for: card, showBranding: showBranding), options: [.sortedKeys]
        ) {
            files["pass.json"] = passJSON
        }
        for (name, image) in makeImages(for: card) {
            if let png = image.pngData() { files[name] = png }
        }
        // The design background (already PNG-encoded at each scale).
        for (name, data) in backgroundImages { files[name] = data }
        return files
    }

    // MARK: - pass.json

    private static func passDictionary(for card: BusinessCard, showBranding: Bool) -> [String: Any] {
        let look = PassAppearance(card: card)

        var dict: [String: Any] = [
            "formatVersion": 1,
            "passTypeIdentifier": PassConstants.passTypeIdentifier,
            "teamIdentifier": PassConstants.teamIdentifier,
            "serialNumber": card.id.uuidString,
            "organizationName": card.company.isEmpty ? PassConstants.organizationName : card.company,
            "description": "\(card.fullName) — Digital Business Card",
            "foregroundColor": look.foregroundRGB,
            "labelColor": look.labelRGB,
            "backgroundColor": look.backgroundRGB,
            "barcodes": [[
                "format": "PKBarcodeFormatQR",
                "message": VCardBuilder.makeVCard(for: card, includePhoto: false),
                "messageEncoding": "iso-8859-1",
                // Free passes carry a subtle attribution under the QR; Pro removes it.
                "altText": showBranding ? brandingText : "Scan for contact"
            ]]
        ]
        if !card.company.isEmpty { dict["logoText"] = card.company }

        var generic: [String: Any] = [:]

        if !card.jobTitle.isEmpty {
            generic["headerFields"] = [field("role", "", card.jobTitle)]
        }
        generic["primaryFields"] = [field("name", "", card.fullName)]

        // With a QR barcode Wallet shows only 4 combined secondary+auxiliary
        // fields, so keep the front lean and push the rest to the back.
        var secondary: [[String: String]] = []
        if !card.email.isEmpty { secondary.append(field("email", "EMAIL", card.email)) }
        let firstPhone = card.phone.isEmpty ? card.mobile : card.phone
        if !firstPhone.isEmpty { secondary.append(field("phone", "PHONE", firstPhone)) }
        if !secondary.isEmpty { generic["secondaryFields"] = secondary }

        var auxiliary: [[String: String]] = []
        if !card.website.isEmpty { auxiliary.append(field("web", "WEBSITE", card.website)) }
        if card.company.isEmpty, !card.city.isEmpty { auxiliary.append(field("city", "LOCATION", card.city)) }
        if !auxiliary.isEmpty { generic["auxiliaryFields"] = auxiliary }

        var back: [[String: String]] = []
        if !card.mobile.isEmpty && card.mobile != firstPhone { back.append(field("bmobile", "Mobile", card.mobile)) }
        if !card.department.isEmpty { back.append(field("bdept", "Department", card.department)) }
        let address = [card.street, card.postalCode, card.city, card.country]
            .filter { !$0.isEmpty }.joined(separator: ", ")
        if !address.isEmpty { back.append(field("baddr", "Address", address)) }
        for social in card.socials where !social.value.isEmpty {
            back.append(field("bsoc_\(social.id.uuidString)", social.platform.title, social.value))
        }
        if !card.notes.isEmpty { back.append(field("bnotes", "Notes", card.notes)) }
        if !back.isEmpty { generic["backFields"] = back }

        dict["eventTicket"] = generic
        return dict
    }

    // MARK: - Images

    private static func makeImages(for card: BusinessCard) -> [String: UIImage] {
        var images: [String: UIImage] = [:]

        for scale in [1, 2, 3] as [CGFloat] {
            if let icon = monogram(card, points: 29, scale: scale) {
                images[name("icon", scale)] = icon
            }
            // Company logo (top-left) — natural aspect, transparent.
            if let logo = logoImage(card, scale: scale) {
                images[name("logo", scale)] = logo
            }
            // Person photo as a square thumbnail (tight centre crop).
            if card.photoData != nil, let thumb = thumbnail(card, points: 90, scale: scale) {
                images[name("thumbnail", scale)] = thumb
            }
        }
        return images
    }

    private static func name(_ base: String, _ scale: CGFloat) -> String {
        scale == 1 ? "\(base).png" : "\(base)@\(Int(scale))x.png"
    }

    private static func logoImage(_ card: BusinessCard, scale: CGFloat) -> UIImage? {
        guard let data = card.logoData, let image = UIImage(data: data),
              image.size.width > 0, image.size.height > 0 else { return nil }
        let maxW: CGFloat = 160, maxH: CGFloat = 50
        let s = min(maxW / image.size.width, maxH / image.size.height)
        let size = CGSize(width: image.size.width * s, height: image.size.height * s)
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    private static func thumbnail(_ card: BusinessCard, points: CGFloat, scale: CGFloat) -> UIImage? {
        guard let data = card.photoData, let image = UIImage(data: data) else { return nil }
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true
        let rect = CGRect(x: 0, y: 0, width: points, height: points)
        return UIGraphicsImageRenderer(size: rect.size, format: format).image { _ in
            let iw = image.size.width, ih = image.size.height
            let s = max(rect.width / iw, rect.height / ih)
            let w = iw * s, h = ih * s
            image.draw(in: CGRect(x: rect.midX - w / 2, y: rect.midY - h / 2, width: w, height: h))
        }
    }

    private static func monogram(_ card: BusinessCard, points: CGFloat, scale: CGFloat) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true
        return UIGraphicsImageRenderer(size: CGSize(width: points, height: points), format: format).image { _ in
            UIColor(PassAppearance(card: card).background).setFill()
            UIRectFill(CGRect(x: 0, y: 0, width: points, height: points))
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: points * 0.42, weight: .semibold),
                .foregroundColor: UIColor.white
            ]
            let s = card.initials as NSString
            let size = s.size(withAttributes: attrs)
            s.draw(at: CGPoint(x: (points - size.width) / 2, y: (points - size.height) / 2),
                   withAttributes: attrs)
        }
    }

    private static func field(_ key: String, _ label: String, _ value: String) -> [String: String] {
        ["key": key, "label": label, "value": value]
    }
}

/// Shared colour logic so the real pass and the in-app preview always match.
/// A dark, muted version of the card's accent — premium, high-contrast,
/// still subtly on-brand for any chosen colour.
struct PassAppearance {
    let background: Color
    let foreground: Color
    let label: Color
    let backgroundRGB: String
    let foregroundRGB: String
    let labelRGB: String

    init(card: BusinessCard) {
        let a = card.theme.accent
        // Deepen the chosen colour into a rich JEWEL tone (keep saturation,
        // cap brightness) so it stays clearly on-brand but reads premium —
        // deep bronze, navy, forest, plum — never neon, never muddy brown.
        let ui = UIColor(red: a.red, green: a.green, blue: a.blue, alpha: 1)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, al: CGFloat = 0
        ui.getHue(&h, saturation: &s, brightness: &b, alpha: &al)

        let bgColor: UIColor
        if s < 0.16 {
            bgColor = UIColor(white: 0.12, alpha: 1)                     // charcoal for greys / black / white
        } else {
            bgColor = UIColor(hue: h,
                              saturation: min(max(s, 0.60), 0.92),
                              brightness: min(b, 0.52),
                              alpha: 1)
        }

        var r: CGFloat = 0, g: CGFloat = 0, bl: CGFloat = 0, aa: CGFloat = 0
        bgColor.getRed(&r, green: &g, blue: &bl, alpha: &aa)

        background = Color(uiColor: bgColor)
        foreground = .white
        label = Color(white: 0.72)
        backgroundRGB = "rgb(\(Int(r * 255)), \(Int(g * 255)), \(Int(bl * 255)))"
        foregroundRGB = "rgb(255, 255, 255)"
        labelRGB = "rgb(184, 184, 190)"
    }
}
