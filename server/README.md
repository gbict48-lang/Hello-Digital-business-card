# Pass signing service

Apple Wallet passes **must** be signed with your *Pass Type ID* certificate. That
private key must never ship inside the app, so signing happens here — a tiny
stateless function. The iOS app builds `pass.json` + images and POSTs them; this
service signs and returns a `.pkpass`.

> The rest of the app (designing cards, QR sharing, saving contacts) works with
> **no** backend. You only need this for the "Add to Apple Wallet" button.

## 1. Create a Pass Type ID + certificate

1. [developer.apple.com](https://developer.apple.com/account) → Certificates, IDs & Profiles → **Identifiers** → **+** → *Pass Type IDs*.
   Use `pass.nl.gbict.hellodigitalbusinesscard` (matches `WalletConfig.passTypeIdentifier`).
2. Create a certificate for that Pass Type ID, download `pass.cer`.
3. Convert to PEM (needs your keychain private key):

```bash
# Export the certificate + key as a .p12 from Keychain Access first, then:
openssl pkcs12 -in Certificates.p12 -clcerts -nokeys -out signerCert.pem
openssl pkcs12 -in Certificates.p12 -nocerts -out signerKey.pem   # set a passphrase
# Apple WWDR intermediate (download AppleWWDRCAG4.cer from Apple, then):
openssl x509 -inform der -in AppleWWDRCAG4.cer -out wwdr.pem
```

## 2. Configure environment variables

Base64-encode each PEM so it fits in one secret line:

```bash
base64 -i wwdr.pem       | tr -d '\n' # -> WWDR_PEM_BASE64
base64 -i signerCert.pem | tr -d '\n' # -> SIGNER_CERT_PEM_BASE64
base64 -i signerKey.pem  | tr -d '\n' # -> SIGNER_KEY_PEM_BASE64
```

| Variable | Value |
|---|---|
| `WWDR_PEM_BASE64` | base64 of `wwdr.pem` |
| `SIGNER_CERT_PEM_BASE64` | base64 of `signerCert.pem` |
| `SIGNER_KEY_PEM_BASE64` | base64 of `signerKey.pem` |
| `SIGNER_KEY_PASSPHRASE` | the passphrase you set on the key |

## 3. Deploy

**Vercel** (easiest):

```bash
cd server
npm i
npx vercel        # then add the env vars in the dashboard, or with `vercel env add`
npx vercel --prod
```

Your endpoint becomes `https://<project>.vercel.app/api`. Paste that into the app
under **Settings → Apple Wallet signing endpoint**.

**Any Node host** (Railway/Render/your own box):

```bash
npm i && npm start        # listens on :3000, endpoint base is http://host:3000
```

## API

`POST {base}/generate-pass`

```json
{ "passJson": { "...": "..." }, "images": { "icon.png": "<base64>" } }
```

Returns `application/vnd.apple.pkpass` on success, or `{ "error": "..." }` on failure.
