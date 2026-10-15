# WisprFlowIsDead website

Static site + two Vercel functions. Vercel project root: `site/`. Served at yourappisdead.com/wisprflowisdead via a rewrite in the root yourappisdead project.

- `/wisprflowisdead` — the one page (homepage + download)
- `/wisprflowisdead/login` — shared yourappisdead Firebase sign-in (email/password + Google)
- `/wisprflowisdead/demo` — public browser dictation and typed practice
- `/wisprflowisdead/api/config` — public Firebase config + `WFID_DOWNLOAD_URL` from env
- `/wisprflowisdead/api/session` — POST `{idToken}` sets the shared `isdead_session` cookie

Env (Vercel): `NEXT_PUBLIC_FIREBASE_API_KEY`, `NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN`, `NEXT_PUBLIC_FIREBASE_PROJECT_ID`, `NEXT_PUBLIC_FIREBASE_APP_ID`, `NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID`, `NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET`, `FIREBASE_SERVICE_ACCOUNT_JSON`, optional `ISDEAD_COOKIE_DOMAIN`, `WFID_DOWNLOAD_URL`.

Preview locally: `npx serve .` from `site/` (APIs need `vercel dev`). Theme: `scripts/sync-design.sh`.

## Website checks

From `site/`: `npm run lint`, `npm run build`, `npm test`. The static build/lint check parses JavaScript and verifies referenced local assets; it does not bundle files or claim browser/accessibility correctness. No dependencies are required for these checks. Firebase APIs still require the dependency and environment above. Deployment root and function configuration are unchanged.

## Browser dictation

The public demo uses `SpeechRecognition` / `webkitSpeechRecognition` on browsers that expose it, over HTTPS or localhost. Microphone access begins only on the recording button or Ctrl+Alt+Space. Escape, cancellation, navigating away, or hiding the tab aborts recognition. A typed practice input runs the same cleanup when speech is unavailable. Four contexts keep separate drafts for the current page session.

Web Speech can send audio to the browser vendor's recognition service; this is **not** the fully local Mac app. This page stores no audio or transcripts. English cleanup is deterministic: conservative fillers/stutters, spoken punctuation, explicit paragraph/bullet commands, and four writing styles. Other languages retain the recognized text. It does not reproduce Wispr's models, unrestricted rewriting, semantic corrections, or automatic language detection. URL/email/code literals are preserved during cleanup. There is no global desktop shortcut or insertion into other apps; copy the result or use the native app.

References: [Web Speech API](https://developer.mozilla.org/en-US/docs/Web/API/SpeechRecognition), [recognition error codes](https://developer.mozilla.org/en-US/docs/Web/API/SpeechRecognitionErrorEvent/error), [original public demo](https://wisprflow.ai/demo). The tests simulate recognition events to verify lifecycle/race/error handling. Real microphone, browser compatibility, keyboard/focus and visual parity checks are still required.

## Login recovery

Sign-in uses the existing Firebase email/password and Google providers with the shared HTTP-only session cookie. Client SDK state stays in memory. Setup has a timeout and retry; requests are locked while pending. New accounts show a confirmation and verification-link resend before continuing to the account page. If session creation fails, Continue retries that account rather than creating another. Password reset uses Firebase email links; no email-code login or additional provider configuration is introduced.

Auth tests mock the SDK/HTTP boundary. They cover errors, request overlap, safe return paths, signup continuation and reset/resend outcomes. Real OAuth, email delivery and the required signup/sign-out/login/sign-out smoke still need a working browser and deployment.

## Personal library

The demo supports personal spellings/corrections and plain-text snippets. Words and triggers are limited to 60 characters; snippet expansions to 4,000; the local library to 1,000 entries. A recording captures the current library when it starts. Matching is literal, whole-phrase and case-insensitive, with longer triggers first. Saved text keeps its casing and line breaks. These are post-recognition replacements, not model training or automatic vocabulary learning.

Entries stay in memory unless the user enables **Keep this library after closing the page**. Only the `wisprflowisdead.library.v1` localStorage key is used. It is browser-profile data, accessible to anyone using that profile, not account-scoped or synced. Turning saving off removes the saved copy and keeps the current page entries; Clear library removes both. Failed writes/deletes and stale cross-tab data show recoverable errors.

Rich-text snippets, team/cloud sync, automatic word learning, bulk import and selection remain unimplemented.
