# Hello Digital Business Card

A free iOS app to **design, share and manage your digital business card**. Share
it with a QR code that anyone can scan to save you straight into their Contacts,
and add your card to **Apple Wallet**.

> **App:** Hello Digital Business Card · **Bundle ID:** `nl.gbict.hellodigitalbusinesscard` · **Team:** `476FB5QW34` · Made by GB ICT.

<p align="center"><em>SwiftUI · iOS 17+ · Liquid Glass · PassKit · Ships to TestFlight via GitHub Actions</em></p>

---

## Features

- 🎨 **Card designer** — name, role, company, contact details, address, social links & photo, with a **live preview** as you type.
- ✨ **Liquid Glass UI** following Apple's latest design language (real `glassEffect` on iOS 26, graceful material fallback on iOS 17–18).
- 🔳 **QR sharing** — a full-screen, high-brightness QR encoding a standards-compliant **vCard**. Anyone scanning it with the Camera app is offered to create the contact. Works fully offline, no account, no backend.
- 👛 **Apple Wallet pass** — add your card to Wallet with the QR on it, so people can scan it straight from your phone.
- 📇 **.vcf export** and native share sheet.
- 🗂 **Multiple cards** with a primary card, persisted locally.
- 🆓 Free.

## Architecture

```
HelloDigitalBusinessCard/
├─ App/                 App entry point
├─ Models/              BusinessCard, CardTheme, RGBAColor  (Codable)
├─ Persistence/         CardStore  (JSON on disk, @Observable)
├─ Services/
│  ├─ VCardBuilder      RFC-6350 vCard string
│  ├─ QRCodeGenerator   CoreImage QR + SwiftUI view
│  └─ Wallet/           PassBuilder · PassSigningClient · WalletService
├─ DesignSystem/        Glass components, BusinessCardView
└─ Features/            Root · Editor · Detail · Share · Settings

server/                 Optional pass-signing function (Vercel / Node)
fastlane/               beta lane → TestFlight
.github/workflows/      ci.yml (build check) · testflight.yml (deploy)
project.yml             XcodeGen spec (generates the .xcodeproj)
```

### Why the QR works everywhere but Wallet needs a tiny backend

The QR code and `.vcf` are generated **entirely on-device** — no server, no cost.
Apple Wallet passes, however, **must be cryptographically signed** with your Pass
Type ID certificate, and that private key must never ship inside an app. So the
app builds the pass and sends it to a small stateless signer that returns a
signed `.pkpass`. See [`server/`](server/README.md). Everything except the "Add
to Wallet" button works without it.

---

## Getting started (local)

```bash
brew install xcodegen
xcodegen generate                 # creates HelloDigitalBusinessCard.xcodeproj
open HelloDigitalBusinessCard.xcodeproj
```

Select your team (already `476FB5QW34`) and run on a device or simulator.

To enable **Add to Wallet**: deploy [`server/`](server/README.md), then paste its
URL into the app under **Settings → Apple Wallet signing endpoint** (or set the
`PassSigningBaseURL` key in `Info.plist`).

---

## Deploy to TestFlight (GitHub Actions)

Push to `main` (or run the **Deploy to TestFlight** workflow manually) and
[`.github/workflows/testflight.yml`](.github/workflows/testflight.yml) will build,
sign and upload a build.

Signing is **fully automatic**: the App Store Connect API key plus
`-allowProvisioningUpdates` lets Xcode create and download the distribution
certificate and provisioning profile on the runner — so you only need **four
secrets**, and no `.p12`/`.mobileprovision` to manage.

Create an API key at App Store Connect → Users and Access → **Integrations →
App Store Connect API**, role **App Manager**. Then add under repository
**Settings → Secrets and variables → Actions**:

| Secret | What it is |
|---|---|
| `APP_STORE_CONNECT_API_KEY` | The downloaded `AuthKey_XXXX.p8` — paste the raw file contents (incl. `-----BEGIN PRIVATE KEY-----`). Base64 is also accepted. |
| `APP_STORE_CONNECT_API_KEY_ID` | The key's ID (e.g. `2X9R4HXF34`) |
| `APP_STORE_CONNECT_ISSUER_ID` | The issuer UUID shown above the keys table |
| `APPLE_TEAM_ID` | `476FB5QW34` |

> The build number is set automatically from the CI run number, so every upload
> is unique. Bump `MARKETING_VERSION` in `project.yml` for a new version.

### First run checklist

1. Register the App ID `nl.gbict.hellodigitalbusinesscard` and create the app record in App Store Connect.
2. Add the four secrets above.
3. Push to `main`. Watch the **Actions** tab; the build appears in TestFlight after Apple finishes processing.

---

## Credits & inspiration

Design follows [Apple's Human Interface Guidelines](https://developer.apple.com/design/resources/).
Concepts were informed by open-source wallet/business-card projects incl.
phatblat/phatblat.pass, amandamcgow, grahamzemel, deljojoseph/wallet-pass,
Leykwan132/quick-card and others.

## License

MIT — see [LICENSE](LICENSE).
