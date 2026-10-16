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

From `site/`: `npm run lint`, `npm run build`, `npm test`. The static build/lint check parses JavaScript and verifies referenced local assets; it does not bundle files or claim browser/accessibility correctness. No dependencies are required for these checks. Firebase APIs still require the dependency and environment above.

Vercel must use **Root Directory `site`** and the **Other** framework preset. `vercel.json` explicitly sets **Output Directory `.`** because the static files already exist in that directory; the validation-only build does not create `public/`. This file-based value overrides a dashboard output-directory setting. Functions remain in `api/`, with the existing `/wisprflowisdead/api/` rewrite. See [Vercel output-directory configuration](https://vercel.com/docs/project-configuration/vercel-json#outputdirectory).

The `qa/parity-evidence-*` branches only archive screenshots and reports, so their automatic Vercel deployments are disabled through `git.deploymentEnabled`. Ordinary feature branches and the production branch retain automatic deployments. See [Vercel Git branch rules](https://vercel.com/docs/project-configuration/git-configuration#git.deploymentenabled). This does not mute deployment-failure notifications or change account preferences.

## Browser dictation

The public demo uses `SpeechRecognition` / `webkitSpeechRecognition` on browsers that expose it, over HTTPS or localhost. Microphone access begins only through a recording action, the configured shortcut (Ctrl+Alt+Space by default), or the explicit microphone check in setup/settings. Escape, cancellation, navigating away, or hiding the tab aborts recognition. A typed practice input runs the same cleanup when speech is unavailable. Four contexts keep separate drafts for the current page session.

Web Speech can send audio to the browser vendor's recognition service; this is **not** the fully local Mac app. This page stores no audio. History is page-only by default, with explicit controls to save text in the browser profile or disable history. English cleanup is deterministic: conservative fillers/stutters, spoken punctuation, explicit paragraph/bullet commands, and four writing styles. Other languages retain the recognized text. It does not reproduce Wispr's models, unrestricted rewriting, semantic corrections, or automatic language detection. URL/email/code literals are preserved during cleanup. There is no global desktop shortcut or insertion into other apps; copy the result or use the native app.

References: [Web Speech API](https://developer.mozilla.org/en-US/docs/Web/API/SpeechRecognition), [recognition error codes](https://developer.mozilla.org/en-US/docs/Web/API/SpeechRecognitionErrorEvent/error), [original public demo](https://wisprflow.ai/demo). The tests simulate recognition events to verify lifecycle/race/error handling. Real microphone, browser compatibility, keyboard/focus and visual parity checks are still required.

## Browser commands

Enable **Command mode**, select an editor passage (or leave no selection to use the whole draft), then speak an instruction or use the typed command field. The existing shortcut acts on the selected mode. Supported English instructions are **uppercase**, **lowercase**, **bullet list**, **numbered list**, **trim spacing**, and **clean up text**. Lists use one nonempty input line per item. Case commands change all letters, including links/code; cleanup retains the ordinary literal protections and chosen language/style. Commands do not expand snippets.

Commands run locally after recognition and have no model/service fee. Unsupported instructions and empty results leave the editor unchanged. Undo edit restores the complete draft before the command. History keeps the selected original passage, result and instruction under the existing retention choice. Input/result is limited to 200,000 characters and instructions to 1,000. Open-ended rewriting, translation, web search, independent native shortcut bindings and system-wide editing remain unsupported; this is a documented free equivalent rather than Wispr's cloud command model.

## Login recovery

Sign-in uses the existing Firebase email/password and Google providers with the shared HTTP-only session cookie. Client SDK state stays in memory. Setup has a timeout and retry; requests are locked while pending. Only email/password and Google are offered. New accounts go straight to the account page with no email verification step; if session creation fails, Continue retries that account rather than creating another. Password reset uses Firebase email links; there is no email-code login, magic link or other provider.

Auth unit tests mock the SDK/HTTP boundary and cover errors, request overlap, safe return paths, signup continuation without verification and reset outcomes. Hosted Chromium now verifies signup/sign-out/login/sign-out with the deployed backend for both live and candidate frontend files, including cookie/server identity checks and disposable-account deletion. See [the parity report](../docs/PARITY_REPORT.md) and [QA instructions](../qa/README.md). Real OAuth, email delivery/reset links and original-account comparison remain unverified.

## Personal library

The demo supports personal spellings/corrections and plain-text snippets. Words and triggers are limited to 60 characters; snippet expansions to 4,000; the local library to 1,000 entries. A recording captures the current library when it starts. Matching is literal, whole-phrase and case-insensitive, with longer triggers first. Saved text keeps its casing and line breaks. These are post-recognition replacements, not model training or automatic vocabulary learning.

Entries stay in memory unless the user enables **Keep this library after closing the page**. Only the `wisprflowisdead.library.v1` localStorage key is used. It is browser-profile data, accessible to anyone using that profile, not account-scoped or synced. Turning saving off removes the saved copy and keeps the current page entries; Clear library removes both. Failed writes/deletes and stale cross-tab data show recoverable errors.

Rich-text snippets, team/cloud sync, automatic word learning, bulk import and selection remain unimplemented.
