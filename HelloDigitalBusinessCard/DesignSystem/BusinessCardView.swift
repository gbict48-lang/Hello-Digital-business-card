import SwiftUI

/// The credit-card-shaped visual representation of a `BusinessCard`.
/// Reused across the list, live editor preview and detail screen.
struct BusinessCardView: View {
    let card: BusinessCard
    var showsQRHint: Bool = false

    private var theme: CardTheme { card.theme }

    var body: some View {
        ZStack {
            background
            content
        }
        .aspectRatio(1.586, contentMode: .fit)   // ISO 7810 ID-1 (credit card) ratio
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(0.18), lineWidth: 0.75)
        )
        .shadow(color: theme.accent.color.opacity(0.35), radius: 24, x: 0, y: 14)
    }

    // MARK: - Background

    @ViewBuilder
    private var background: some View {
        switch theme.style {
        case .gradient:
            LinearGradient(
                colors: [theme.accent.color, theme.secondary.color],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .solid:
            theme.accent.color
        case .mono:
            theme.accent.color
        case .glass:
            ZStack {
                LinearGradient(
                    colors: [theme.accent.color, theme.secondary.color],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                Color.clear.glassSurface(RoundedRectangle(cornerRadius: 28, style: .continuous))
            }
        }
    }

    // MARK: - Content

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                avatar
                Spacer()
                if showsQRHint {
                    Image(systemName: "qrcode")
                        .font(.title3)
                        .foregroundStyle(theme.secondaryTextColor)
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(card.fullName.isEmpty ? "Your Name" : card.fullName)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(theme.textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if !card.jobTitle.isEmpty {
                    Text(card.jobTitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(theme.textColor)
                        .lineLimit(1)
                }
                if !card.company.isEmpty {
                    Text(card.company)
                        .font(.subheadline)
                        .foregroundStyle(theme.secondaryTextColor)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 10)

            HStack(spacing: 14) {
                if !card.email.isEmpty {
                    Label(card.email, systemImage: "envelope.fill")
                        .labelStyle(.iconOnlyIfNeeded)
                }
                if !card.phone.isEmpty || !card.mobile.isEmpty {
                    Image(systemName: "phone.fill")
                }
                ForEach(card.socials.prefix(3)) { social in
                    Image(systemName: social.platform.symbol)
                }
                Spacer()
            }
            .font(.caption)
            .foregroundStyle(theme.secondaryTextColor)
            .lineLimit(1)
        }
        .padding(22)
    }

    private var avatar: some View {
        Group {
            if let data = card.photoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Circle().fill(.white.opacity(0.22))
                    Text(card.initials)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(theme.textColor)
                }
            }
        }
        .frame(width: 52, height: 52)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(.white.opacity(0.35), lineWidth: 1))
    }
}

/// A label style that hides the title when space is tight (keeps card clean).
private struct IconOnlyIfNeededStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 4) { configuration.icon; configuration.title }
            configuration.icon
        }
    }
}

extension LabelStyle where Self == IconOnlyIfNeededStyle {
    static var iconOnlyIfNeeded: IconOnlyIfNeededStyle { .init() }
}

#Preview {
    BusinessCardView(card: .sample, showsQRHint: true)
        .padding()
}
