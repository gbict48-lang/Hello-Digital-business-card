import { signPass } from "../lib/signPass.js";

/**
 * Vercel serverless function.  POST /api/generate-pass
 * Body: { passJson: {...}, images: { "icon.png": base64, ... } }
 * Returns: signed application/vnd.apple.pkpass
 */
export default async function handler(req, res) {
  if (req.method !== "POST") {
    res.status(405).json({ error: "Method not allowed" });
    return;
  }

  try {
    const body = typeof req.body === "string" ? JSON.parse(req.body) : req.body;
    const pkpass = await signPass(body);

    res.setHeader("Content-Type", "application/vnd.apple.pkpass");
    res.setHeader("Content-Disposition", "attachment; filename=card.pkpass");
    res.status(200).send(pkpass);
  } catch (error) {
    console.error("Pass signing failed:", error);
    res.status(500).json({ error: error.message });
  }
}
