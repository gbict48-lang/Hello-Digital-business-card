import SwiftUI
import AuthenticationServices

/// A polished, paged intro shown on first launch. The final page offers Sign in
/// with Apple (optional) and a "Maybe later" escape hatch.
struct OnboardingView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(\.colorScheme) private var colorScheme
    @State private var page = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            symbol: "hand.wave.fill",
            title: "Hello 👋",
            message: "Your business card, reimagined. Beautiful, digital, and always in your pocket.",
            tint: Color(hex: "#0A84FF")
        ),
        OnboardingPage(
            symbol: "paintbrush.pointed.fill",
            title: "Design it your way",
            message: "Pick colours, themes and a photo. Watch your card come to life as you type.",
            tint: Color(hex: "#BF5AF2")
        ),
        OnboardingPage(
            symbol: "qrcode",
            title: "Share in a tap",
            message: "Show a QR code and anyone can save you to their contacts — or add your card to Apple Wallet.",
            tint: Color(hex: "#30D158")
        )
    ]

    var body: some View {
        ZStack {
            AnimatedBackground(tint: currentTint)

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                    finalPage
                        .tag(pages.count)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.smooth, value: page)

                PageDots(count: pages.count + 1, current: page)
                    .padding(.bottom, 24)

                bottomControls
                    .padding(.horizontal, 28)
                    .padding(.bottom, 40)
            }
        }
    }

    private var currentTint: Color {
        page < pages.count ? pages[page].tint : Color(hex: "#0A84FF")
    }

    // MARK: - Final page

    private var finalPage: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 84, weight: .medium))
                .foregroundStyle(.white, Color(hex: "#0A84FF"))
                .symbolRenderingMode(.palette)
            Text("Get started")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
            Text("Sign in with Apple to sync your name and keep your cards yours. It's optional — you can always skip.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            Spacer()
        }
    }

    // MARK: - Bottom controls

    @ViewBuilder
    private var bottomControls: some View {
        if page < pages.count {
            Button {
                withAnimation(.smooth) { page += 1 }
            } label: {
                Text("Continue").frame(maxWidth: .infinity)
            }
            .buttonStyle(GlassButtonStyle(prominent: true))
        } else {
            VStack(spacing: 14) {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    auth.handle(result)
                    auth.completeOnboarding()
                }
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 52)
                .clipShape(Capsule())

                Button("Maybe later") {
                    auth.completeOnboarding()
                }
                .font(.callout.weight(.medium))
                .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Pieces

private struct OnboardingPage {
    let symbol: String
    let title: String
    let message: String
    let tint: Color
}

private struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle()
                    .fill(page.tint.opacity(0.18))
                    .frame(width: 180, height: 180)
                    .blur(radius: 6)
                Image(systemName: page.symbol)
                    .font(.system(size: 88, weight: .semibold))
                    .foregroundStyle(page.tint)
                    .symbolRenderingMode(.hierarchical)
                    .scaleEffect(appeared ? 1 : 0.6)
                    .opacity(appeared ? 1 : 0)
            }
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)
                Text(page.message)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { appeared = true }
        }
    }
}

private struct PageDots: View {
    let count: Int
    let current: Int
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? Color.primary : Color.secondary.opacity(0.3))
                    .frame(width: index == current ? 22 : 8, height: 8)
                    .animation(.smooth, value: current)
            }
        }
    }
}

/// A soft, slowly shifting gradient that picks up the current page's tint.
struct AnimatedBackground: View {
    let tint: Color
    var body: some View {
        LinearGradient(
            colors: [tint.opacity(0.22), Color(.systemBackground)],
            startPoint: .top, endPoint: .center
        )
        .ignoresSafeArea()
        .animation(.smooth(duration: 0.8), value: tint)
        .overlay(alignment: .top) {
            tint.opacity(0.25)
                .frame(height: 200)
                .blur(radius: 90)
                .ignoresSafeArea()
                .animation(.smooth(duration: 0.8), value: tint)
        }
    }
}
