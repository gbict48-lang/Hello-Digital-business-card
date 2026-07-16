import Foundation
import UIKit
import SwiftUI

/// Builds the raw files for an Apple Wallet pass. Signed & zipped on-device by
/// `PassSigner`.
///
/// Follows Apple's Wallet HIG: a clean `generic` pass with ONE solid background
/// colour, high-contrast text, a small set of fields, and the photo shown as a
/// square thumbnail (Wallet rounds it) — never a stretched image. The in-app
/// `WalletPassPreview` mirrors this exactly.
enum PassBuilder {

    static func makeFiles(for card: BusinessCard) -> [String: Data] {
        var files: [String: Data] = [:]
        if let passJSON = try? JSONSerialization.data(
            withJSONObject: passDictionary(for: card), options: [.sortedKeys]
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
        let appearance = PassAppearance(card: card)

        var dict: [String: Any] = [
            "formatVersion": 1,
            "passTypeIdentifier": PassConstants.passTypeIdentifier,
            "teamIdentifier": PassConstants.teamIdentifier,
            "serialNumber": card.id.uuidString,
            "organizationName": card.company.isEmpty ? PassConstants.organizationName : card.company,
            "description": "\(card.fullName) — Digital Business Card",
            "foregroundColor": appearance.foregroundRGB,
            "labelColor": appearance.labelRGB,
            "backgroundColor": appearance.backgroundRGB,
            "barcodes": [[
                "format": "PKBarcodeFormatQR",
                "message": VCardBuilder.makeVCard(for: card, includePhoto: false),
                "messageEncoding": "iso-8859-1",
                "altText": card.fullName
            ]]
        ]
        if !card.company.isEmpty { dict["logoText"] = card.company }

        var generic: [String: Any] = [
            "primaryFields": [field("name", "", card.fullName)]
        ]

        var secondary: [[String: String]] = []
        if !card.jobTitle.isEmpty { secondary.append(field("role", "ROLE", card.jobTitle)) }
        if card.company.isEmpty, !card.city.isEmpty {
            secondary.append(field("city", "LOCATION", card.city))
        }
        if !secondary.isEmpty { generic["secondaryFields"] = secondary }

        var auxiliary: [[String: String]] = []
        if !card.email.isEmpty { auxiliary.append(field("email", "EMAIL", card.email)) }
        let firstPhone = card.phone.isEmpty ? card.mobile : card.phone
        if !firstPhone.isEmpty { auxiliary.append(field("phone", "PHONE", firstPhone)) }
        if !auxiliary.isEmpty { generic["auxiliaryFields"] = auxiliary }

        var back: [[String: String]] = []
        if !card.mobile.isEmpty && card.mobile != firstPhone { back.append(field("bmobile", "Mobile", card.mobile)) }
        if !card.website.isEmpty { back.append(field("bweb", "Website", card.website)) }
        let address = [card.street, card.postalCode, card.city, card.country]
            .filter { !$0.isEmpty }.joined(separator: ", ")
        if !address.isEmpty { back.append(field("baddr", "Address", address)) }
        for social in card.socials where !social.value.isEmpty {
            back.append(field("bsoc_\(social.id.uuidString)", social.platform.title, social.value))
        }
        if !card.notes.isEmpty { back.append(field("bnotes", "Notes", card.notes)) }
        if !back.isEmpty { generic["backFields"] = back }

        dict["generic"] = generic
        return dict
    }

    // MARK: - Images

    private static func makeImages(for card: BusinessCard) -> [String: UIImage] {
        var images: [String: UIImage] = [:]

        // Required icon (square monogram — used on the lock screen / notifications).
        for scale in [1, 2, 3] as [CGFloat] {
            if let icon = monogram(card, points: 29, scale: scale) {
                images[scale == 1 ? "icon.png" : "icon@\(Int(scale))x.png"] = icon
            }
        }

        // Square photo thumbnail (Wallet rounds it). Only when a photo exists.
        if card.photoData != nil {
            for scale in [1, 2, 3] as [CGFloat] {
                if let thumb = thumbnail(card, points: 90, scale: scale) {
                    images[scale == 1 ? "thumbnail.png" : "thumbnail@\(Int(scale))x.png"] = thumb
                }
            }
        }
        return images
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
            card.theme.accent.uiColor.setFill()
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
struct PassAppearance {
    let background: Color
    let foreground: Color
    let label: Color
    let backgroundRGB: String
    let foregroundRGB: String
    let labelRGB: String

    init(card: BusinessCard) {
        let accent = card.theme.accent
        let isLight = (0.299 * accent.red + 0.587 * accent.green + 0.114 * accent.blue) > 0.6
        background = accent.color
        foreground = isLight ? Color(hex: "#111114") : .white
        label = isLight ? Color(hex: "#5A5A5F") : Color(white: 1, opacity: 0.82)
        backgroundRGB = "rgb(\(Int(accent.red * 255)), \(Int(accent.green * 255)), \(Int(accent.blue * 255)))"
        foregroundRGB = isLight ? "rgb(17, 17, 20)" : "rgb(255, 255, 255)"
        labelRGB = isLight ? "rgb(90, 90, 95)" : "rgb(235, 235, 245)"
    }
}
