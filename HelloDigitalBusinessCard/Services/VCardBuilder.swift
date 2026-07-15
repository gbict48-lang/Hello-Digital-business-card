import Foundation

/// Builds a standards-compliant vCard (RFC 6350 / 3.0) from a `BusinessCard`.
///
/// The vCard string is what gets encoded into the QR code — when another
/// person scans it, iOS (and Android) offers to create a new contact directly,
/// no app required on their side.
enum VCardBuilder {

    /// - Parameters:
    ///   - card: the card to encode.
    ///   - includePhoto: embed the avatar as a base64 PHOTO. Keep this `false`
    ///     for QR codes — photos make the payload far too large to scan. Use
    ///     `true` only when exporting a `.vcf` file.
    static func makeVCard(for card: BusinessCard, includePhoto: Bool = false) -> String {
        var lines: [String] = []
        lines.append("BEGIN:VCARD")
        lines.append("VERSION:3.0")

        // N: Family;Given;Additional;Prefix;Suffix
        lines.append("N:\(esc(card.lastName));\(esc(card.firstName));;;")
        lines.append("FN:\(esc(card.fullName))")

        if !card.company.isEmpty || !card.department.isEmpty {
            lines.append("ORG:\(esc(card.company));\(esc(card.department))")
        }
        if !card.jobTitle.isEmpty {
            lines.append("TITLE:\(esc(card.jobTitle))")
        }
        if !card.phone.isEmpty {
            lines.append("TEL;TYPE=WORK,VOICE:\(esc(card.phone))")
        }
        if !card.mobile.isEmpty {
            lines.append("TEL;TYPE=CELL,VOICE:\(esc(card.mobile))")
        }
        if !card.email.isEmpty {
            lines.append("EMAIL;TYPE=INTERNET,WORK:\(esc(card.email))")
        }
        if !card.website.isEmpty {
            lines.append("URL:\(esc(card.website))")
        }

        // ADR: PO;Extended;Street;City;Region;PostalCode;Country
        let hasAddress = ![card.street, card.city, card.postalCode, card.country]
            .allSatisfy(\.isEmpty)
        if hasAddress {
            lines.append("ADR;TYPE=WORK:;;\(esc(card.street));\(esc(card.city));;\(esc(card.postalCode));\(esc(card.country))")
        }

        for social in card.socials where !social.value.isEmpty {
            // Extra profile URLs are added as generic URL entries with a label.
            lines.append("URL;TYPE=\(social.platform.title):\(esc(social.value))")
        }

        if !card.notes.isEmpty {
            lines.append("NOTE:\(esc(card.notes))")
        }

        if includePhoto, let data = card.photoData {
            // Fold long base64 lines per the spec (75 octets, continuation = space).
            let base64 = data.base64EncodedString()
            lines.append(foldPhotoLine("PHOTO;ENCODING=b;TYPE=PNG:\(base64)"))
        }

        lines.append("REV:\(iso8601(card.updatedAt))")
        lines.append("END:VCARD")

        return lines.joined(separator: "\r\n")
    }

    // MARK: - Helpers

    /// Escapes characters that are special in vCard text values.
    private static func esc(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ";", with: "\\;")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: "\n", with: "\\n")
    }

    private static func iso8601(_ date: Date) -> String {
        let f = ISO8601DateFormatter()
        return f.string(from: date)
    }

    private static func foldPhotoLine(_ line: String) -> String {
        var result = ""
        var count = 0
        for char in line {
            if count == 74 {
                result += "\r\n "
                count = 1
            }
            result.append(char)
            count += 1
        }
        return result
    }
}
