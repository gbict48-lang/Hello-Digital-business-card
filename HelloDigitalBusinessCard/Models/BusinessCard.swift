import Foundation

/// A single social / web profile attached to a card.
struct SocialLink: Codable, Hashable, Identifiable {
    enum Platform: String, Codable, CaseIterable, Identifiable {
        case linkedin, instagram, x, github, facebook, tiktok, youtube, whatsapp, website, custom
        var id: String { rawValue }

        var title: String {
            switch self {
            case .linkedin: "LinkedIn"
            case .instagram: "Instagram"
            case .x: "X"
            case .github: "GitHub"
            case .facebook: "Facebook"
            case .tiktok: "TikTok"
            case .youtube: "YouTube"
            case .whatsapp: "WhatsApp"
            case .website: "Website"
            case .custom: "Link"
            }
        }

        /// SF Symbol used in the UI.
        var symbol: String {
            switch self {
            case .linkedin, .facebook, .youtube, .tiktok, .instagram, .x, .github:
                "link"
            case .whatsapp: "message.fill"
            case .website: "globe"
            case .custom: "link"
            }
        }
    }

    var id: UUID = UUID()
    var platform: Platform
    /// A full URL or handle. Stored as the user typed it.
    var value: String
}

/// The core model. Everything needed to render a card, build a vCard, a QR
/// code and a Wallet pass.
struct BusinessCard: Codable, Hashable, Identifiable {
    var id: UUID = UUID()

    // Identity
    var firstName: String = ""
    var lastName: String = ""
    var jobTitle: String = ""
    var company: String = ""
    var department: String = ""

    // Contact
    var phone: String = ""
    var mobile: String = ""
    var email: String = ""
    var website: String = ""

    // Address
    var street: String = ""
    var city: String = ""
    var postalCode: String = ""
    var country: String = ""

    // Extras
    var notes: String = ""
    var socials: [SocialLink] = []

    /// Avatar / logo, stored as PNG data so the card is self-contained.
    var photoData: Data?

    var theme: CardTheme = .default

    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var fullName: String {
        [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
    }

    var displayTitle: String {
        [jobTitle, company].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    var initials: String {
        let f = firstName.first.map(String.init) ?? ""
        let l = lastName.first.map(String.init) ?? ""
        let result = (f + l).uppercased()
        return result.isEmpty ? "?" : result
    }

    var hasContent: Bool {
        !fullName.isEmpty || !company.isEmpty || !email.isEmpty || !phone.isEmpty
    }

    static let sample = BusinessCard(
        firstName: "Alex",
        lastName: "de Vries",
        jobTitle: "Product Designer",
        company: "GB ICT",
        phone: "+31 20 123 4567",
        mobile: "+31 6 1234 5678",
        email: "alex@gbict.nl",
        website: "https://gbict.nl",
        city: "Amsterdam",
        country: "Netherlands",
        socials: [
            SocialLink(platform: .linkedin, value: "https://linkedin.com/in/alexdevries"),
            SocialLink(platform: .github, value: "https://github.com/gbict48-lang")
        ],
        theme: .presets[0]
    )
}
