import SwiftUI

@main
struct HelloDigitalBusinessCardApp: App {
    @State private var store = CardStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .tint(.accentColor)
        }
    }
}
