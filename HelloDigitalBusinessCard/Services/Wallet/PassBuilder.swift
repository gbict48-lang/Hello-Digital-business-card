import Foundation
import UIKit

/// Builds the raw files for an Apple Wallet pass for a business card:
/// `pass.json` plus images. Signed & zipped on-device by `PassSigner`.
///
/// Apple Wallet has a fixed layout, so we can't reproduce the app card exactly
/// (no gradient backgrounds). Instead we render a **strip banner** — a gradient
/// with the person's circular photo + name + role — so the card's design still
/// comes across. The vCard is the QR barcode so it can be scanned from Wallet.
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

    // MARK: - pass.json (storeCard with a designed strip)

    private static func passDictionary(for card: BusinessCard) -> [String: Any] {
        let accent = card.theme.accent
        let lightBackground = luminance(accent) > 0.6
        let fg = lightBackground ? "rgb(17, 17, 20)" : "rgb(255, 255, 255)"
        let label = lightBackground ? "rgb(70, 70, 74)" : "rgb(235, 235, 245)"

        var dict: [String: Any] = [
            "formatVersion": 1,
            "passTypeIdentifier": PassConstants.passTypeIdentifier,
            "teamIdentifier": PassConstants.teamIdentifier,
            "serialNumber": card.id.uuidString,
            "organizationName": card.company.isEmpty ? PassConstants.organizationName : card.company,
            "description": "\(card.fullName) — Digital Business Card",
            "foregroundColor": fg,
            "labelColor": label,
            "backgroundColor": rgb(from: accent),
            "barcodes": [[
                "format": "PKBarcodeFormatQR",
                "message": VCardBuilder.makeVCard(for: card, includePhoto: false),
                "messageEncoding": "iso-8859-1",
                "altText": card.fullName
            ]]
        ]

        var store: [String: Any] = [:]

        var header: [[String: String]] = []
        if !card.jobTitle.isEmpty { header.append(field("role", "", card.jobTitle)) }
        if !header.isEmpty { store["headerFields"] = header }

        var secondary: [[String: String]] = []
        if !card.email.isEmpty { secondary.append(field("email", "EMAIL", card.email)) }
        if !card.phone.isEmpty { secondary.append(field("phone", "PHONE", card.phone)) }
        else if !card.mobile.isEmpty { secondary.append(field("mobile", "MOBILE", card.mobile)) }
        if !secondary.isEmpty { store["secondaryFields"] = secondary }

        var auxiliary: [[String: String]] = []
        if !card.website.isEmpty { auxiliary.append(field("web", "WEBSITE", card.website)) }
        if !card.mobile.isEmpty && !card.phone.isEmpty { auxiliary.append(field("mobile", "MOBILE", card.mobile)) }
        if !auxiliary.isEmpty { store["auxiliaryFields"] = auxiliary }

        var back: [[String: String]] = []
        if !card.mobile.isEmpty { back.append(field("bmobile", "Mobile", card.mobile)) }
        if !card.website.isEmpty { back.append(field("bweb", "Website", card.website)) }
        let address = [card.street, card.postalCode, card.city, card.country]
            .filter { !$0.isEmpty }.joined(separator: ", ")
        if !address.isEmpty { back.append(field("baddr", "Address", address)) }
        for social in card.socials where !social.value.isEmpty {
            back.append(field("bsoc_\(social.id.uuidString)", social.platform.title, social.value))
        }
        if !card.notes.isEmpty { back.append(field("bnotes", "Notes", card.notes)) }
        if !back.isEmpty { store["backFields"] = back }

        dict["storeCard"] = store
        return dict
    }

    // MARK: - Images

    private static func makeImages(for card: BusinessCard) -> [String: UIImage] {
        var images: [String: UIImage] = [:]

        // Required icon (square monogram, never stretched).
        if let i1 = monogram(card, points: 29, scale: 1) { images["icon.png"] = i1 }
        if let i2 = monogram(card, points: 29, scale: 2) { images["icon@2x.png"] = i2 }
        if let i3 = monogram(card, points: 29, scale: 3) { images["icon@3x.png"] = i3 }

        // Small square logo top-left (monogram — square, no stretch).
        if let l1 = monogram(card, points: 40, scale: 1) { images["logo.png"] = l1 }
        if let l2 = monogram(card, points: 40, scale: 2) { images["logo@2x.png"] = l2 }
        if let l3 = monogram(card, points: 40, scale: 3) { images["logo@3x.png"] = l3 }

        // The designed banner.
        images["strip.png"] = stripImage(for: card, scale: 1)
        images["strip@2x.png"] = stripImage(for: card, scale: 2)
        images["strip@3x.png"] = stripImage(for: card, scale: 3)

        return images
    }

    /// Renders the gradient banner with a circular photo/monogram + name + role.
    private static func stripImage(for card: BusinessCard, scale: CGFloat) -> UIImage {
        let size = CGSize(width: 375, height: 144)
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        return renderer.image { context in
            let cg = context.cgContext

            // Gradient background.
            let space = CGColorSpaceCreateDeviceRGB()
            let colors = [card.theme.accent.uiColor.cgColor, card.theme.secondary.uiColor.cgColor] as CFArray
            if let gradient = CGGradient(colorsSpace: space, colors: colors, locations: [0, 1]) {
                cg.drawLinearGradient(gradient, start: .zero,
                                      end: CGPoint(x: size.width, y: size.height), options: [])
            }

            let onLight = luminance(card.theme.accent) > 0.6
            let textColor: UIColor = onLight ? UIColor(white: 0.07, alpha: 1) : .white

            // Circular avatar.
            let d: CGFloat = 96
            let circle = CGRect(x: 22, y: (size.height - d) / 2, width: d, height: d)
            cg.saveGState()
            UIBezierPath(ovalIn: circle).addClip()
            if let data = card.photoData, let image = UIImage(data: data) {
                drawAspectFill(image, in: circle)
            } else {
                (onLight ? UIColor(white: 0, alpha: 0.15) : UIColor(white: 1, alpha: 0.25)).setFill()
                cg.fill(circle)
                drawCentered(card.initials, in: circle,
                             font: .systemFont(ofSize: 38, weight: .bold), color: textColor)
            }
            cg.restoreGState()
            cg.setStrokeColor(UIColor.white.withAlphaComponent(0.55).cgColor)
            cg.setLineWidth(2)
            cg.strokeEllipse(in: circle.insetBy(dx: 1, dy: 1))

            // Name + role with a soft shadow for legibility on any gradient.
            let shadow = NSShadow()
            shadow.shadowColor = UIColor.black.withAlphaComponent(0.28)
            shadow.shadowBlurRadius = 4
            shadow.shadowOffset = CGSize(width: 0, height: 1)

            let textX = circle.maxX + 20
            let textWidth = size.width - textX - 16

            let name = card.fullName.isEmpty ? "Your Name" : card.fullName
            (name as NSString).draw(in: CGRect(x: textX, y: 40, width: textWidth, height: 40),
                                    withAttributes: [
                                        .font: UIFont.systemFont(ofSize: 30, weight: .bold),
                                        .foregroundColor: textColor,
                                        .shadow: shadow
                                    ])
            if !card.displayTitle.isEmpty {
                (card.displayTitle as NSString).draw(
                    in: CGRect(x: textX, y: 80, width: textWidth, height: 24),
                    withAttributes: [
                        .font: UIFont.systemFont(ofSize: 16, weight: .medium),
                        .foregroundColor: textColor.withAlphaComponent(0.9),
                        .shadow: shadow
                    ])
            }
        }
    }

    // MARK: - Drawing helpers

    private static func drawAspectFill(_ image: UIImage, in rect: CGRect) {
        let iw = image.size.width, ih = image.size.height
        guard iw > 0, ih > 0 else { return }
        let scale = max(rect.width / iw, rect.height / ih)
        let w = iw * scale, h = ih * scale
        image.draw(in: CGRect(x: rect.midX - w / 2, y: rect.midY - h / 2, width: w, height: h))
    }

    private static func drawCentered(_ text: String, in rect: CGRect, font: UIFont, color: UIColor) {
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let s = text as NSString
        let size = s.size(withAttributes: attrs)
        s.draw(at: CGPoint(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2),
               withAttributes: attrs)
    }

    private static func monogram(_ card: BusinessCard, points: CGFloat, scale: CGFloat) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: points, height: points), format: format)
        return renderer.image { _ in
            card.theme.accent.uiColor.setFill()
            UIRectFill(CGRect(x: 0, y: 0, width: points, height: points))
            drawCentered(card.initials, in: CGRect(x: 0, y: 0, width: points, height: points),
                         font: .systemFont(ofSize: points * 0.42, weight: .semibold), color: .white)
        }
    }

    // MARK: - Small helpers

    private static func field(_ key: String, _ label: String, _ value: String) -> [String: String] {
        ["key": key, "label": label, "value": value]
    }

    private static func luminance(_ c: RGBAColor) -> Double {
        0.299 * c.red + 0.587 * c.green + 0.114 * c.blue
    }

    private static func rgb(from color: RGBAColor) -> String {
        "rgb(\(Int(color.red * 255)), \(Int(color.green * 255)), \(Int(color.blue * 255)))"
    }
}
