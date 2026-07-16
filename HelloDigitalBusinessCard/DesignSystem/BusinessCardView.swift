import SwiftUI

/// The credit-card-shaped visual representation of a `BusinessCard`.
/// Reused across the list, live editor preview and detail screen.
struct BusinessCardView: View {
    let card: BusinessCard
    var showsQRHint: Bool = false

    private var theme: CardTheme { card.theme }
    private let shape = RoundedRectangle(cornerRadius: 26, style: .continuous)

    var body: some View {
        ZStack {
            backgroundView
            contentView
        }
        .aspectRatio(1.586, contentMode: .fit)          // ISO ID-1 credit-card ratio
        .clipShape(shape)
        .overlay(shape.strokeBorder(.white.opacity(theme.isLightSurface ? 0.5 : 0.16), lineWidth: 0.75))
        .shadow(color: theme.accent.color.opacity(0.30), radius: 22, x: 0, y: 12)
    }

    // MARK: - Backgrounds (one per template)

    @ViewBuilder
    private var backgroundView: some View {
        switch theme.style {
        case .gradient:
            LinearGradient(colors: [theme.accent.color, theme.secondary.color],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay(
                RadialGradient(colors: [.white.opacity(0.22), .clear],
                               center: .topTrailing, startRadius: 4, endRadius: 320)
            )

        case .glass:
            LinearGradient(colors: [theme.accent.color, theme.secondary.color],
                           startPoint: .top, endPoint: .bottom)
            .overlay(
                RadialGradient(colors: [.white.opacity(0.25), .clear],
                               center: .topLeading, startRadius: 4, endRadius: 260)
            )

        case .aurora:
            ZStack {
                Color(hex: "#0B0B12")
                RadialGradient(colors: [theme.accent.color.opacity(0.95), .clear],
                               center: .topLeading, startRadius: 0, endRadius: 300)
                RadialGradient(colors: [theme.secondary.color.opacity(0.9), .clear],
                               center: .bottomTrailing, startRadius: 0, endRadius: 320)
                RadialGradient(colors: [theme.accent.color.opacity(0.5), .clear],
                               center: UnitPoint(x: 0.8, y: 0.15), startRadius: 0, endRadius: 180)
            }

        case .spotlight:
            ZStack {
                Color(hex: "#0A0A0F")
                RadialGradient(colors: [theme.accent.color.opacity(0.75), .clear],
                               center: UnitPoint(x: 0.24, y: 0.30), startRadius: 0, endRadius: 260)
                RadialGradient(colors: [theme.secondary.color.opacity(0.35), .clear],
                               center: .bottomTrailing, startRadius: 0, endRadius: 240)
            }

        case .minimal:
            ZStack {
                Color(hex: "#F4F4F7")
                Text(card.initials)
                    .font(.system(size: 150, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.accent.color.opacity(0.10))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .offset(x: 30, y: 30)
                VStack {
                    Rectangle().fill(theme.accent.color).frame(height: 6)
                    Spacer()
                }
            }

        case .bold:
            ZStack {
                theme.accent.color
                LinearGradient(colors: [.white.opacity(0.14), .clear],
                               startPoint: .topLeading, endPoint: .center)
                Text(card.initials)
                    .font(.system(size: 200, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(0.12))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .offset(x: 34, y: 44)
            }
        }
    }

    // MARK: - Content

    private var contentView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                avatar
                Spacer(minLength: 8)
                if showsQRHint { qrBadge }
            }

            Spacer(minLength: 12)

            infoBlock
        }
        .padding(20)
    }

    private var infoBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(card.fullName.isEmpty ? "Your Name" : card.fullName)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(theme.foreground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                if !card.displayTitle.isEmpty {
                    Text(card.displayTitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(theme.secondaryForeground)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }

            chipsRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.style == .glass ? 14 : 0)
        .background {
            if theme.style == .glass {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.clear)
                    .glassSurface(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }

    private var chipsRow: some View {
        HStack(spacing: 8) {
            if !card.email.isEmpty { chip("envelope.fill") }
            if !card.phone.isEmpty || !card.mobile.isEmpty { chip("phone.fill") }
            if !card.website.isEmpty { chip("globe") }
            ForEach(card.socials.prefix(3)) { social in
                chip(social.platform.symbol)
            }
            if !hasAnyContact { chip("qrcode") }   // never look empty
            Spacer(minLength: 0)
        }
    }

    private var hasAnyContact: Bool {
        !card.email.isEmpty || !card.phone.isEmpty || !card.mobile.isEmpty
            || !card.website.isEmpty || !card.socials.isEmpty
    }

    private func chip(_ symbol: String) -> some View {
        let tint = theme.isLightSurface ? theme.accent.color : Color.white
        return Image(systemName: symbol)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: 30, height: 30)
            .background(
                Circle().fill(theme.isLightSurface
                              ? theme.accent.color.opacity(0.14)
                              : Color.white.opacity(0.18))
            )
    }

    private var qrBadge: some View {
        Image(systemName: "qrcode")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(theme.foreground)
            .frame(width: 34, height: 34)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(theme.isLightSurface
                          ? theme.accent.color.opacity(0.12)
                          : Color.white.opacity(0.18))
            )
    }

    // MARK: - Avatar (always a clean circle, never stretched)

    private var avatar: some View {
        ZStack {
            if let data = card.photoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                theme.isLightSurface
                    ? theme.accent.color.opacity(0.16)
                    : Color.white.opacity(0.22)
                Text(card.initials)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.isLightSurface ? theme.accent.color : theme.foreground)
            }
        }
        .frame(width: 58, height: 58)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(.white.opacity(theme.isLightSurface ? 0.6 : 0.4), lineWidth: 1.5))
    }
}

#Preview {
    VStack(spacing: 16) {
        ForEach(Array(CardTheme.Style.allCases.prefix(3)), id: \.self) { style in
            BusinessCardView(card: {
                var c = BusinessCard.sample; c.theme.style = style; return c
            }(), showsQRHint: true)
        }
    }
    .padding()
}
