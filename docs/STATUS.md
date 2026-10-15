# Status

## App (macOS 14+, Apple silicon) — builds, 43 FlowCore tests pass (macOS + Linux)
Done: push-to-talk / hands-free (fn, Esc and fn swallowed while dictating), on-device transcription (FluidAudio, vendored from MyMan),
polish (FoundationModels on macOS 26, rule fallback), backtrack, personal dictionary + snippets + learn-from-correction (with Undo),
styles per app, context awareness (AX selection/field/window terms), paste with clipboard restore (type fallback),
microphone ranking/picker, saved audio with Retry/Recover/playback, Transforms (Polish, Prompt Engineer, custom),
floating Scratchpad (⌥S), Notetaker (mic + system audio, transcript, summary, Markdown), Flow bar, Hub, onboarding, original app icon,
Figtree + EB Garamond theme from isdead-design.

Not hands-on verified yet: live dictation into real apps, system-audio permission prompt, key swallowing under Secure Input.

## Website (site/) — one page + /login
`/wisprflowisdead` (homepage with download), `/wisprflowisdead/login` (shared yourappisdead Firebase auth), two Vercel functions.

## Needs Tommy
- OK to create the GitHub repo and push (download section points at github.com/tommy-muckstack/wisprflowisdead).
- Vercel project for `site/` + env vars (Firebase web config, FIREBASE_SERVICE_ACCOUNT_JSON, optional WFID_DOWNLOAD_URL).
- Root yourappisdead `vercel.json` rewrite for /wisprflowisdead (replaces the coming-soon page).
- Signed/notarized build (out of scope until approved).
