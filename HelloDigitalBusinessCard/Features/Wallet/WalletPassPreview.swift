import SwiftUI

/// A faithful in-app preview of the Apple Wallet pass, so the user sees exactly
/// what they'll get before adding it. Mirrors `PassBuilder`'s generic layout and
/// shares `PassAppearance` for identical colours.
struct WalletPassPreview: View {
    let card: BusinessCard

    private var look: PassAppearance { PassAppearance(card: card) }

    private var firstPhone: String { card.phone.isEmpty ? card.mobile : card.phone }
    private var vcard: String { VCardBuilder.makeVCard(for: card, includePhoto: false) }

    var body: some View {
        VStack(spacing: 0) {
            header
            primary
            fields
            Spacer(minLength: 12)
            qr
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(look.background)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.25), radius: 18, y: 10)
    }

    // MARK: - Sections

    private var header: some View {
        HStack {
            Text(card.company.isEmpty ? "WALLET" : card.company.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(look.foreground)
                .lineLimit(1)
            Spacer()
        }
        .padding(.bottom, 20)
    }

    private var primary: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(card.fullName.isEmpty ? "Your Name" : card.fullName)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(look.foreground)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                if !card.jobTitle.isEmpty {
                    Text(card.jobTitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(look.label)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            thumbnail
        }
        .padding(.bottom, 20)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let data = card.photoData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 68, height: 68)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(.white.opacity(0.35), lineWidth: 1))
        }
    }

    private var fields: some View {
        HStack(alignment: .top, spacing: 22) {
            if !card.email.isEmpty { fieldCell("EMAIL", card.email) }
            if !firstPhone.isEmpty { fieldCell("PHONE", firstPhone) }
            if !card.website.isEmpty && card.email.isEmpty { fieldCell("WEBSITE", card.website) }
            Spacer(minLength: 0)
        }
    }

    private func fieldCell(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(look.label)
            Text(value)
                .font(.footnote.weight(.medium))
                .foregroundStyle(look.foreground)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private var qr: some View {
        QRCodeView(payload: vcard)
            .frame(width: 150, height: 150)
            .padding(12)
            .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .frame(maxWidth: .infinity)
    }
}
