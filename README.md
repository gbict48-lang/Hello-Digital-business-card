# Hello Digital Business Card

A free iOS app to **design, share and manage your digital business card**. Share
it with a QR code that anyone can scan to save you straight into their Contacts,
and add your card to **Apple Wallet** — all on-device, no backend.

> **App:** Hello Digital Business Card · **Bundle ID:** `nl.gbict.hellodigitalbusinesscard` · **Team:** `476FB5QW34` · Made by GB ICT.

<p align="center"><em>SwiftUI · iOS 17+ · Liquid Glass · Sign in with Apple · PassKit · Ships to TestFlight via GitHub Actions</em></p>

---

## Features

- 👋 **Onboarding & Sign in with Apple** — a polished paged intro, then optional one-tap Apple sign-in that pre-fills your first card. No passwords, no accounts to manage.
- 🎨 **Card designer** — name, role, company, contact details, address, social links & photo, with a **live preview** as you type, themes and colour pickers.
- ✨ **Liquid Glass UI** following Apple's latest design language (real `glassEffect` on iOS 26, graceful material fallback on iOS 17–18).
- 🔳 **QR sharing** — a full-screen, high-brightness QR encoding a standards-compliant **vCard**. Anyone scanning it with the Camera app is offered to create the contact. Fully offline.
- 👛 **Apple Wallet pass** — built and **signed entirely on-device** (no server), with the QR on it so people can scan it straight from Wallet.
- 📇 **.vcf export** and native share sheet, multiple cards with a primary card, stored locally.
- 🆓 Free. Nothing for the user to configure — it just works.

## Architecture

```
HelloDigitalBusinessCard/
├─ App/                 App entry + onboarding gate
├─ Auth/                AuthManager (Sign in with Apple)
├─ Models/              BusinessCard, CardTheme, RGBAColor  (Codable)
├─ Persistence/         CardStore  (JSON on disk, @Observable)
├─ Services/
│  ├─ VCardBuilder      RFC-6350 vCard string
│  ├─ QRCodeGenerator   CoreImage QR + SwiftUI view
│  └─ Wallet/           PassBuilder · PassSigner (on-device CMS) · PassCredentials · WalletService
├─ DesignSystem/        Glass components, BusinessCardView
└─ Features/            Onboarding · Root · Editor · Detail · Share · Profile

.github/workflows/      ci.yml (build check) · testflight.yml (deploy)
project.yml             XcodeGen spec (generates the .xcodeproj)
```

### On-device Wallet signing (no backend)

A `.pkpass` **must** be cryptographically signed with a Pass Type ID
certificate — that's a hard Apple requirement no app can skip. Instead of a
server, this app signs **on-device** using Apple's own
[`swift-certificates`](https://github.com/apple/swift-certificates) (CMS/PKCS#7)
plus [`ZIPFoundation`](https://github.com/weichsel/ZIPFoundation):

1. build `pass.json` + images → 2. `manifest.json` (SHA-1 of each file) →
3. detached CMS signature of the manifest → 4. zip into a `.pkpass`.

The signing certificate is bundled into the app **at build time from GitHub
secrets** (never committed), so **end users configure nothing**. If those secrets
aren't set, the app still builds and runs perfectly — it just hides the "Add to
Wallet" button. QR sharing always works.

---

## Getting started (local)

```bash
brew install xcodegen
xcodegen generate                 # resolves SPM packages + creates the .xcodeproj
open HelloDigitalBusinessCard.xcodeproj
```

Select your team (already `476FB5QW34`) and run. To test Wallet locally, drop
`pass_certificate.pem`, `pass_key.pem` and `wwdr.pem` into
`HelloDigitalBusinessCard/Resources/` (they're git-ignored) and regenerate.

---

## Deploy to TestFlight (GitHub Actions)

Push to `main` (or run the **Deploy to TestFlight** workflow manually).
Signing is **fully automatic** via the App Store Connect API key + Xcode's
`-allowProvisioningUpdates` — no `.p12`/profile juggling.

### Required secrets (build & upload)

| Secret | What it is |
|---|---|
| `APP_STORE_CONNECT_API_KEY` | The `AuthKey_XXXX.p8` contents (or base64) |
| `APP_STORE_CONNECT_API_KEY_ID` | The key's ID |
| `APP_STORE_CONNECT_ISSUER_ID` | The issuer UUID |
| `APPLE_TEAM_ID` | `476FB5QW34` |

### Optional secrets (enable Apple Wallet)

Add these to turn on the on-device Wallet feature. Create a **Pass Type ID**
(`pass.nl.gbict.hellodigitalbusinesscard`) and its certificate in the Developer
portal, then convert to unencrypted PEM and base64-encode each:

| Secret | What it is |
|---|---|
| `PASS_CERTIFICATE_PEM_BASE64` | Pass Type ID certificate (PEM), base64 |
| `PASS_KEY_PEM_BASE64` | Its **unencrypted** RSA private key (PEM), base64 |
| `WWDR_PEM_BASE64` | Apple WWDR intermediate cert (PEM), base64 |

```bash
# from a Certificates.p12 exported from Keychain:
openssl pkcs12 -in Certificates.p12 -clcerts -nokeys -out pass_certificate.pem
openssl pkcs12 -in Certificates.p12 -nocerts -nodes -out pass_key.pem     # -nodes = no passphrase
openssl x509 -inform der -in AppleWWDRCAG4.cer -out wwdr.pem
base64 -i pass_certificate.pem | tr -d '\n'   # -> PASS_CERTIFICATE_PEM_BASE64  (etc.)
```

> Without the optional secrets the app is still fully functional; the Wallet
> button is simply hidden. Sign in with Apple works automatically (Xcode adds the
> capability during provisioning).

### First run checklist

1. Register the App ID `nl.gbict.hellodigitalbusinesscard` and create the app record in App Store Connect.
2. Add the four required secrets (and optionally the three Wallet ones).
3. Push to `main`. The build appears in TestFlight after Apple finishes processing.

---

## Credits & inspiration

Design follows [Apple's Human Interface Guidelines](https://developer.apple.com/design/resources/).
Concepts were informed by open-source wallet/business-card projects incl.
phatblat/phatblat.pass, amandamcgow, grahamzemel, deljojoseph/wallet-pass,
Leykwan132/quick-card and others.

## License

MIT — see [LICENSE](LICENSE).
