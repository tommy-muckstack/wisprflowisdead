# WisprFlowIsDead website

Static site + two Vercel functions. Vercel project root: `site/`. Served at yourappisdead.com/wisprflowisdead via a rewrite in the root yourappisdead project.

- `/wisprflowisdead` — the one page (homepage + download)
- `/wisprflowisdead/login` — shared yourappisdead Firebase sign-in (email/password + Google)
- `/wisprflowisdead/api/config` — public Firebase config + `WFID_DOWNLOAD_URL` from env
- `/wisprflowisdead/api/session` — POST `{idToken}` sets the shared `isdead_session` cookie

Env (Vercel): `NEXT_PUBLIC_FIREBASE_API_KEY`, `NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN`, `NEXT_PUBLIC_FIREBASE_PROJECT_ID`, `NEXT_PUBLIC_FIREBASE_APP_ID`, `NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID`, `NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET`, `FIREBASE_SERVICE_ACCOUNT_JSON`, optional `ISDEAD_COOKIE_DOMAIN`, `WFID_DOWNLOAD_URL`.

Preview locally: `npx serve .` from `site/` (APIs need `vercel dev`). Theme: `scripts/sync-design.sh`.
