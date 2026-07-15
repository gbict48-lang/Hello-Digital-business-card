import SwiftUI

@main
struct HelloDigitalBusinessCardApp: App {
    @State private var store = CardStore()
    @State private var auth = AuthManager()

    var body: some Scene {
        WindowGroup {
            AppContainerView()
                .environment(store)
                .environment(auth)
                .tint(.accentColor)
        }
    }
}

/// Switches between the first-run onboarding and the main app.
private struct AppContainerView: View {
    @Environment(AuthManager.self) private var auth

    var body: some View {
        Group {
            if auth.hasCompletedOnboarding {
                RootView()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.smooth(duration: 0.4), value: auth.hasCompletedOnboarding)
    }
}
