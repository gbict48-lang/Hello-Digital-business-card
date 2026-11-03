import SwiftUI

/// In-app Privacy Policy and Terms of Use — always available (App Review wants
/// these reachable, and the paywall links to them).
struct LegalView: View {
    enum Document { case privacy, terms }
    let document: Document
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(.init(document == .privacy ? Self.privacy : Self.terms))
                    .font(.callout)
                    .tint(.accentColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
            }
            .navigationTitle(document == .privacy ? "Privacy Policy" : "Terms of Use")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }

    static let contact = "hello@gbict.nl"

    static let privacy = """
    **Privacy Policy**

    *Last updated: 2026*

    Hello Digital Business Card ("the app") is made by GB ICT. We designed it to respect your privacy.

    **What we collect:** nothing. The app does **not** collect, transmit, or sell your personal data. There are no analytics or tracking SDKs.

    **Where your data lives:** the cards you create — names, contact details, photos and company logos — are stored **only on your device**. They are never uploaded to us.

    **Sign in with Apple (optional):** if you choose to sign in, Apple provides your name and email so we can personalise your first card. This is stored only on your device and is never shared. You can use the entire app without signing in.

    **Purchases:** the optional Pro upgrade is handled entirely by Apple via the App Store. We never see your payment details. Apple's privacy policy applies to the transaction.

    **Apple Wallet:** passes you create are generated and signed on your device and added to Apple Wallet by you. We do not receive them.

    **Children:** the app is not directed at children and collects no data from anyone.

    **Your rights:** because your data stays on your device, you remain in full control — delete a card, or delete the app, and it is gone.

    **Contact:** questions? Email \(contact).
    """

    static let terms = """
    **Terms of Use**

    *Last updated: 2026*

    By using Hello Digital Business Card ("the app"), you agree to these terms.

    **Licence:** GB ICT grants you a personal, non-transferable licence to use the app on devices you own, under the Apple Media Services Terms and Conditions (the standard EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/

    **Pro upgrade:** the app is free to create one card. "Hello Card Pro" is a one-time, non-consumable in-app purchase that unlocks unlimited cards, your company logo and every design. It is tied to your Apple ID and can be restored on your devices. Purchases are processed by Apple; refunds are handled by Apple under their policies.

    **Your content:** you are responsible for the information on your cards and for having the right to use any logos or images you add. Don't use the app to impersonate others or share unlawful content.

    **No warranty:** the app is provided "as is", without warranties of any kind. To the maximum extent permitted by law, GB ICT is not liable for any damages arising from its use.

    **Changes:** we may update the app and these terms. Continued use means you accept the changes.

    **Contact:** \(contact).
    """
}
