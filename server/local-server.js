import express from "express";
import { signPass } from "./lib/signPass.js";

// Plain Express server for local testing or any Node host (Railway, Render, …).
// The iOS app posts to  <baseURL>/generate-pass  so we mount it there too.
const app = express();
app.use(express.json({ limit: "5mb" }));

app.get("/health", (_req, res) => res.json({ ok: true }));

async function handle(req, res) {
  try {
    const pkpass = await signPass(req.body);
    res.setHeader("Content-Type", "application/vnd.apple.pkpass");
    res.setHeader("Content-Disposition", "attachment; filename=card.pkpass");
    res.send(pkpass);
  } catch (error) {
    console.error("Pass signing failed:", error);
    res.status(500).json({ error: error.message });
  }
}

app.post("/generate-pass", handle);
app.post("/api/generate-pass", handle);

const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`Pass signer listening on :${port}`));
