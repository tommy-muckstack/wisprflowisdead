// POST {idToken} → shared httpOnly 'isdead_session' cookie (path "/") so one sign-in covers every IsDead app.
// DELETE → sign out. Mirrors isdead-design/auth/server.ts.
const admin = require("firebase-admin");
const COOKIE = "isdead_session", MAX_AGE_S = 60 * 60 * 24 * 14;
function app() {
  if (admin.apps.length) return admin.app();
  const sa = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!sa) return null;
  return admin.initializeApp({ credential: admin.credential.cert(JSON.parse(sa)) });
}
function cookie(value, maxAge) {
  const domain = process.env.ISDEAD_COOKIE_DOMAIN ? `; Domain=${process.env.ISDEAD_COOKIE_DOMAIN}` : "";
  return `${COOKIE}=${value}; Path=/; Max-Age=${maxAge}; HttpOnly; Secure; SameSite=Lax${domain}`;
}
function readCookie(req) { const m = (req.headers.cookie || "").split(/;\s*/).find(c => c.startsWith(COOKIE + "=")); return m ? m.slice(COOKIE.length + 1) : null; }
module.exports = async (req, res) => {
  if (req.method === "GET") { // who am I? { email, name } or 401
    res.setHeader("cache-control", "no-store");
    const a = app(), v = readCookie(req);
    if (!a || !v) return res.status(401).json({ error: "Not signed in" });
    try { const d = await a.auth().verifySessionCookie(v, true); return res.status(200).json({ uid: d.uid || null, email: d.email || null, name: d.name || null }); }
    catch { return res.status(401).json({ error: "Not signed in" }); }
  }
  if (req.method === "DELETE") { res.setHeader("set-cookie", cookie("", 0)); return res.status(204).end(); }
  if (req.method !== "POST") { res.setHeader("allow", "GET, POST, DELETE"); return res.status(405).json({ error: "Method not allowed" }); }
  const a = app();
  if (!a) return res.status(503).json({ error: "Sign-in isn't configured yet." });
  const idToken = req.body && req.body.idToken;
  if (typeof idToken !== "string") return res.status(400).json({ error: "Missing idToken" });
  try {
    const decoded = await a.auth().verifyIdToken(idToken, true);
    if (Date.now() / 1000 - decoded.auth_time > 5 * 60) return res.status(401).json({ error: "Please sign in again." });
    const session = await a.auth().createSessionCookie(idToken, { expiresIn: MAX_AGE_S * 1000 });
    res.setHeader("set-cookie", cookie(session, MAX_AGE_S));
    return res.status(204).end();
  } catch { return res.status(401).json({ error: "Could not verify your sign-in." }); }
};
