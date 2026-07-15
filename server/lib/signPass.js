import { PKPass } from "passkit-generator";

/**
 * Turns a { passJson, images } request body into a signed .pkpass buffer.
 *
 * Certificates are read from environment variables (all PEM, base64-encoded so
 * they survive as single-line secrets):
 *   - WWDR_PEM_BASE64          Apple WWDR intermediate certificate (PEM)
 *   - SIGNER_CERT_PEM_BASE64   Your Pass Type ID certificate (PEM)
 *   - SIGNER_KEY_PEM_BASE64    The matching private key (PEM)
 *   - SIGNER_KEY_PASSPHRASE    Passphrase for the private key (optional)
 */
export async function signPass(body) {
  const { passJson, images } = body ?? {};
  if (!passJson || typeof passJson !== "object") {
    throw new Error("Missing 'passJson' in request body.");
  }

  const decode = (name) => {
    const value = process.env[name];
    if (!value) throw new Error(`Missing environment variable ${name}`);
    return Buffer.from(value, "base64").toString("utf8");
  };

  const certificates = {
    wwdr: decode("WWDR_PEM_BASE64"),
    signerCert: decode("SIGNER_CERT_PEM_BASE64"),
    signerKey: decode("SIGNER_KEY_PEM_BASE64"),
    signerKeyPassphrase: process.env.SIGNER_KEY_PASSPHRASE || undefined,
  };

  // Assemble the pass file map: pass.json + every image the app sent.
  const buffers = {
    "pass.json": Buffer.from(JSON.stringify(passJson)),
  };
  for (const [name, base64] of Object.entries(images ?? {})) {
    buffers[name] = Buffer.from(base64, "base64");
  }

  const pass = new PKPass(buffers, certificates);
  return pass.getAsBuffer();
}
