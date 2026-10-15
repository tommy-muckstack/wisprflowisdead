# WisprFlowIsDead parity report

Audit date: 2026-10-15. Upstream baseline: `71e3e684ff333da4732ad92da5347d446e9feec7`.
Scope: marketing website, shared Firebase account flow, and a browser dictation experience. The native Swift app is a separate, existing implementation.

**Not complete. Login now scores 93.6 desktop / 91.9 mobile; home and pricing remain below 90. Live and candidate signup/sign-out/login/sign-out pass, including disposable-account deletion. Section/state comparison, original-account behavior, email delivery, OAuth and real audio remain outstanding.**

## Evidence and environment

- Read the repository README, website README, existing product spec, upstream contributing guide, and shared parity/smoke scripts. No repository AGENTS.md or .env.example exists at the baseline.
- Git cloning failed with DNS errors even with escalation. Retrieved 78 files through the GitHub connector and verified each Git blob SHA against the pinned tree. Two native-only TTF files were not retrieved; all website files and fonts are present. The local import commit is not an upstream commit and must not be pushed as the PR base.
- `site/` is the Vercel project root; functions are in `site/api/`. At baseline only home, pricing, login, and app HTML routes exist; the browser dictation change adds `/demo`. There are no website lint/build/test scripts at baseline.
- Public text/navigation inspected on [home](https://wisprflow.ai), [pricing](https://wisprflow.ai/pricing), [get started](https://wisprflow.ai/get-started), and the [help center](https://docs.wisprflow.ai). Hosted runs subsequently captured home/pricing/login and computed styles at both widths. The original's open menus/hover states and documentation article layouts remain unverified.
- No reference captures at `/workspace/isdead-shots/parity/wisprflowisdead/`. The local in-app browser execution tool is unavailable. Standalone Playwright Chromium fails at launch with macOS `bootstrap_check_in ... MachPortRendezvousServer` permission errors, including escalated attempts.
- The user subsequently supplied a paired desktop screenshot (`image (10).png`, original left, clone right) and prioritized the navigation bar. It is useful reference evidence, but its two panels do not establish equal viewport widths or a measured parity score. Installed Google Chrome was also attempted through Playwright and exited before navigation.
- Cached Playwright Firefox and WebKit were also attempted against the local server with escalation. Both abort before navigation (`SIGABRT` / `Abort trap: 6`). The local HTTP server responds, but no installed engine has produced a website screenshot.
- A separate Chrome QA instance was attempted through macOS Launch Services, using a fresh temporary profile and localhost-only debugging for Playwright CDP attachment. Application-name lookup failed; opening the known bundle path returned `kLSNoExecutableErr` (missing executable). No personal browser profile was used and no browser session was established.
- Local `npm install` for both website and parity tooling fails with `ENOTFOUND registry.npmjs.org`. The hosted runner installs the pinned browser tools and exercises the existing deployed APIs; local API startup remains unavailable. No environment values or secrets were read, changed, or committed.
- A static preview was started at `http://127.0.0.1:3300/wisprflowisdead/` after socket-binding approval. This Python fallback serves `.html` paths; it does not emulate Vercel clean URLs or functions.
- `scripts/parity.mjs --config parity/wispr.json --clone https://yourappisdead.com --viewports 1440x900,390x844` was attempted: missing package dependency prevents capture. `templates/smoke2.mjs https://yourappisdead.com/wisprflowisdead wispr-account` was attempted: browser launch fails before navigation. No accounts were created, so there are none to delete.
- An original desktop installation already exists. It was not launched or inspected, and no existing personal account was used. Original email signup, onboarding and free-plan eligibility still need hands-on checks; no SSO, paid trial or payment was used.
- GitHub-hosted macOS/Linux runners are available. Native CI has verified all 43 tests plus complete app/icon assembly after restoring an executable bit. [Website run 38788448067](https://github.com/tommy-muckstack/wisprflowisdead/actions/runs/38788448067) completed Chromium captures, computed styles and scores. All twelve parity page loads returned 200; the workflow correctly failed the 90+ score/overflow gate. Its [92-file artifact](https://github.com/tommy-muckstack/wisprflowisdead/actions/runs/38788448067/artifacts/11999281233) is available until 2026-10-29.
- The GitHub connector downloaded that artifact to a reusable file reference, but direct local download still fails DNS even with escalation. The follow-up run archived public evidence on [qa/parity-evidence-38790232733-1](https://github.com/tommy-muckstack/wisprflowisdead/tree/qa/parity-evidence-38790232733-1/docs/parity/38790232733-1). Original/candidate desktop home and mobile pricing viewports, the candidate mobile pricing full page, and pricing computed styles were inspected through the GitHub connection. Pricing uses a 64 px mobile heading versus the original 48 px, its controls and cards sit lower, and the full-page capture includes unwanted space to the right.

## Score ledger

`N/M` means not measured. User-provided approximate scores are historical context only. The first hosted measurements below compare production with the entire PR stack at `b68249428dbc218844f4798534e46da403a4d6e4`, using shared tools at `3020a26628341fa65dbf5759b9b69cffc913d2aa`. They do not attribute a change to an individual PR. Original screenshots were reused for the candidate comparison. Scores and HTTP status are established; screenshot/style inspection and per-feature review are still required.

| Page | Viewport | Historical context | Before | After | Screenshots |
|---|---|---|---|---|---|
| Home | 1440 × 900 | — | 79.1 | 79.0 | Run 38788448067: `live/`, `candidate/home-1440-side.png` |
| Home | 390 × 844 | approximately 62, supplied in task | 61.9 | 56.9 | Run 38788448067: `live/`, `candidate/home-390-side.png` |
| Pricing | 1440 × 900 | approximately 76, supplied in task | 75.0 | 57.0 | Run 38788448067: `live/`, `candidate/pricing-1440-side.png` |
| Pricing | 390 × 844 | — | 75.1 | 59.3 | Run 38788448067: `live/`, `candidate/pricing-390-side.png`; candidate overflows to 732 px |
| Login | 1440 × 900 | — | 79.0 | 78.1 | Run 38788448067: `live/`, `candidate/login-1440-side.png` |
| Login | 390 × 844 | — | 78.5 | 67.5 | Run 38788448067: `live/`, `candidate/login-390-side.png` |

Latest verified candidate at `a155b9138506b8660ea6b5831d36237d9d152601`, [run 38797508456](https://github.com/tommy-muckstack/wisprflowisdead/actions/runs/38797508456): home **79.0 / 56.9**, pricing **67.9 / 59.5**, login **93.6 / 91.9** (desktop/mobile). All six browser interaction groups and both auth smokes pass, with both disposable accounts deleted and no capture errors or page overflow. Home/pricing still fail the unchanged 90+ gate. The login layout change improves **78.1 → 93.6 (+15.5)** and **67.5 → 91.9 (+24.4)** against the preceding candidate measured with the same 26-second login wait. Actual scored images were inspected: [desktop side-by-side](https://github.com/tommy-muckstack/wisprflowisdead/blob/qa/parity-evidence-38797508456-1/docs/parity/38797508456-1/candidate/login-1440-side.png), [mobile side-by-side](https://github.com/tommy-muckstack/wisprflowisdead/blob/qa/parity-evidence-38797508456-1/docs/parity/38797508456-1/candidate/login-390-side.png). These are initial-viewport scores; whole-page footer geometry and later auth states remain separate review items.

## Feature matrix

Status is `match`, `differs`, or `missing`. `Differs` includes implementations awaiting comparison; it does not mean that a fix was visually verified. Severity: P0 blocks the requested core experience; P1 breaks an important flow; P2 is a noticeable presentation/accessibility gap. The evidence column names source files or tests. Feature-specific screenshot/score entries remain N/M; the page-level captures above do not prove every feature or state.

| Page / feature | Status | Severity | Evidence / remaining work | Screenshots / score |
|---|---|---|---|---|
| Website/native branding and icons | differs | P2 | User-requested tombstone renders in home/login/account captures; E11. Native icon assembly passes; Dock/menu-bar visual checks remain | Hosted raw/auth captures; native CI |
| Home: banner, navigation, menus | differs | P1 | Desktop CTA overlap check and mobile open/Escape/focus/Pricing navigation pass. Mobile bar is 358×62 vs reference ≈347×54; original open-menu comparison remains | Home 79.0 / 56.9; hosted raw captures |
| Home: hero layout, type, colors, spacing | differs | P1 | Measured mobile heading 44 vs original 48 px, subtitle three vs two lines, CTA placement/ribbon differ | Home 79.0 / 56.9; hosted styles/raw |
| Home: hero art and animation | differs | P2 | Original SVG lettering and CSS wave bars; E1 | N/M |
| Home: logo strip | differs | P2 | App-name compatibility strip replaces customer marks; E2 | N/M |
| Home: speed comparison and scroll demos | differs | P1 | Unsupported speed claims removed; linear fallback for reduced motion, small viewports and no JS; desktop scroll stages still need rendered comparison | N/M |
| Home: feature grid and style preview | differs | P2 | Linked tab/panel semantics, arrow/Home/End navigation and focus styling implemented; browser verification pending | N/M |
| Home: privacy/security card | differs | P2 | Mac-local processing distinguished from browser service; no external certification claims, E3 | N/M |
| Home: testimonials | differs | P2 | Anonymous quotes replaced with factual product cards; intentional E2, layout comparison pending | N/M |
| Home: FAQ, CTA and download | differs | P1 | Minimum OS corrected to 14.2; limited FAQ and source-build fallback remain | N/M |
| Home: mobile layout | differs | P1 | No page overflow in hosted checks. Several linear feature panels stay green where the original switches to cream; type/order/art still differ | 56.9; hosted styles/raw |
| Home/pricing: footer and links | missing | P1 | Most original destinations absent; complete inventory below | N/M |
| Cookie/privacy controls | differs | P2 | Footer says no tracking/cookie banner; verify scripts/storage before validating E4 | N/M |
| Pricing: cards and billing toggle | differs | P1 | Both-width billing/add-on controls pass. Mobile first card position matches within ≈1 px; default add-on and other typography/art differ, E5 | 67.9 / 59.5; run 38792121104 |
| Pricing: compare table | differs | P1 | Table roles and text alternatives; #15 restores stacked mobile labels, contains overflow and verifies all four plans remain reachable; row/section geometry still differs | N/M |
| Pricing: ROI calculator | differs | P2 | Bounded finite inputs, visible errors and disclosed assumptions; invalid/valid result browser checks pass at both widths; visual comparison remains | N/M |
| Pricing: FAQ | differs | P2 | Hosted desktop tab/mobile accordion interaction passes. Original mobile starts collapsed; candidate starts with its first answer open; heading/section geometry differs | Hosted behavior/raw pricing captures |
| Pricing: security card and CTA | differs | P2 | Mac/browser processing distinction and explicit absence of certifications; source/support destinations preserve E3/E5 | N/M |
| Pricing: mobile card collapse | differs | P2 | Linked controls and no-JS fallback; mobile expansion passes in hosted Chromium; remaining typography/plan details differ | N/M |
| Login: visual layout | differs | P2 | Initial card/heading/provider-row/CTA placement matches measured reference geometry at both widths; project art, branding, provider availability and full-page footer differ | **93.6 / 91.9**; run 38797508456 |
| Login: Google sign-in/button | differs | P1 | Existing official gradient G retained; approved white/gray/Google Sans treatment restored; popup/rendering untested | N/M |
| Login: Apple/Microsoft/SSO | missing | P1 | Unavailable providers are disabled with visible explanation; E6, configuration decision required | N/M |
| Email login/signup | differs | P1 | Live and candidate smoke pass with matching server identity/cookie flags; original email-code behavior remains E6 | `auth/{live,candidate}.json`, run 38794977597 |
| Password reset and verification | differs | P1 | Reset view and verification-link resend added; Firebase link verification differs from original email-code flow, E6 | N/M |
| Auth validation/error/loading | differs | P1 | Live/candidate SDK reaches ready state; successful flow verified; rendered invalid/reset/provider/error recovery still pending | Settled login captures, run 38794977597 |
| Account identity/loading | differs | P1 | Matching test identity renders after signup/login at both widths; loading/retry failure injection and original account comparison remain | Masked `auth/*-account-*.png`, run 38794977597 |
| Account sign-out | differs | P1 | Both UI sign-outs pass on live/candidate, with server 401 and cookie absence before test cleanup; failure recovery/original comparison remain | `auth/{live,candidate}.json`, run 38794977597 |
| Home/pricing account access | differs | P2 | Navigation change moves account access to footer/mobile menu; sign-out uses account page recovery flow | N/M |
| Browser dictation demo | differs | P0 | `/demo` uses Web Speech with typed fallback; live microphone/browser validation pending, E7/E9 | N/M |
| Idle/listening/transcribing/polishing/result | differs | P0 | State machine includes permission, cancellation, recovery and timeout states; unit-tested, browser pending | N/M |
| Filler removal/punctuation/formatting | differs | P0 | Conservative local English rules, spoken punctuation/paragraphs/bullets; E7 | N/M |
| Tone/style options | differs | P1 | Four deterministic English styles in demo; no model rewriting, E7 | N/M |
| Personal dictionary | differs | P1 | Hosted creation, literal correction, opt-in save and reload pass. Search/sort/star/edit/delete need rendered coverage; recognition bias/learning remains E7 | Hosted demo behavior at both widths |
| Snippets | differs | P1 | Hosted creation and multiline case-preserving expansion pass. Other CRUD states, rich text/import/sync and original layout remain unverified | Hosted demo behavior at both widths |
| Command mode | differs | P1 | Browser selection/whole-draft voice or typed commands, undo and instruction history implemented; finite local commands, native/model behavior remains E7/E8/E9 | N/M |
| History/copy/delete/recovery | differs | P1 | Hosted entries, opt-in persistence/reload and clear-all pass. Copy/search/individual deletion/recovery need rendered coverage; audio replay/retry unavailable | Hosted demo behavior at both widths |
| Settings: hotkey/language/microphone | differs | P1 | Settings dialog adds language/style persistence, custom focused-page shortcut, hold/toggle activation and bounded microphone level check; native device picker/global shortcuts remain E8/E9 | N/M |
| Settings: privacy/storage | differs | P1 | Library saving is opt-in; history offers page-only, 24-hour, until-deleted and disabled modes; browser/account isolation and real retention checks pending | N/M |
| Browser onboarding | differs | P1 | Hosted skip and remembered completion pass. Real microphone/practice progression, reopening/focus and native comparison remain unverified | Hosted demo behavior at both widths |
| Microphone denied/unavailable/no speech | differs | P0 | Recoverable messages and timeouts tested with injected recognizer; real permissions/audio pending | N/M |
| Keyboard/focus/reduced motion | differs | P1 | Nav/demo tab keyboard and focus behavior drafted; demo/auth reduced-motion rules exist; sitewide manual accessibility verification pending | N/M |
| Branded 404 | missing | P2 | No 404 page or site-level route | N/M |

## Original navigation/footer inventory

Observed public destinations, deduplicated, as of the audit date. A hash link to a generic home section is **not** a matching destination. The [hosted home/pricing link inventory](https://github.com/tommy-muckstack/wisprflowisdead/blob/qa/parity-evidence-38792121104-1/docs/parity/38792121104-1/raw/inventory.json) confirms the rendered navigation/footer links at both widths; closed-menu visibility does not establish open-menu behavior. Hover states and links inside every article remain to be inspected. Clone routes are relative to `/wisprflowisdead`.

| Original destination | Clone destination / status | Reason or work required |
|---|---|---|
| `/` (Dictation) | `/` — differs | Main parity work outstanding |
| `/notetaker` | `#notetaker` — missing page | Footer card only; dedicated page absent |
| `/get-started` (download/get app) | `/login`, `#download` — differs | Email account and native source-build handoff differ |
| `/pricing` | `/pricing` — differs | E5; visual comparison pending |
| `/privacy` | `#privacy` — missing page | Security summary only |
| `/demo` | `/demo` — differs | Browser dictation draft; rendered/audio comparison pending |
| `/why-flow` | missing | Needs original, evidence-backed comparison |
| `/microphones` | missing | Needs accurate browser/native microphone help |
| `https://store.wisprflow.ai/` | missing | E10: no merchandise store or inventory |
| `/business` | `#teams` — missing page | No shared team admin; avoid implying availability |
| `/lab` | `#lab` — missing page | Home section does not reproduce the dedicated destination |
| `/leaders` | missing | Use-case page absent |
| `/developers` | `#teams` — missing page | Generic section is not a use-case page |
| `/content-creators` | missing | Use-case page absent |
| `/customer-support` | missing | Use-case page absent |
| `/students` | `#teams` — missing page | Generic section is not a use-case page |
| `/lawyers` | missing | Use-case page absent; do not claim compliance |
| `/accessibility` | `#teams` — missing page | Must accurately describe tested capabilities |
| `/sales` | missing | Use-case page absent |
| `/case-studies` | missing | E2: no verified clone customer evidence |
| `/blog` | missing | No original articles exist |
| `/ai-prompting-guide` | missing | Needs original educational content |
| `/workflows` | missing | Needs tested clone workflows |
| `/flow-vs-gboard-typing` | missing | Comparison page absent |
| `/flow-vs-apple-dictation` | missing | Comparison page absent |
| `/whats-new` | missing | Can link real release/commit history; no invented releases |
| `/vibe-coding` | missing | Educational/use-case page absent |
| `/bug-bounty` | missing | E10: no funded bounty program established |
| `/support` | `#faq` — missing page | Needs actual support path to repository issues |
| `/talk-to-sales` | missing | E5/E10: free project, no sales organization |
| `https://docs.wisprflow.ai/` | missing | README/spec are not a browser help center |
| `/about` | missing | Needs factual independent-project page |
| `/careers` | missing | E10: no employment openings established |
| `https://trust.wispr.ai/` | missing | E3: no clone certification/trust portal |
| `https://partners.dub.co/flow` | missing | E10: no clone affiliate program |
| `/media-kit` | missing | Can provide only project-owned, licensed assets |
| `/terms-of-service` | missing | License is not hosted-service terms; maintainer decision required |
| `/privacy-policy` | missing | Must describe actual Firebase and browser data handling |
| `/data-controls` | missing | Needs accurate browser storage/account controls |
| Do Not Sell/Privacy Settings controls | differs | Original action returns home in text crawl; actual modal unverified, E4 |
| `https://wisprflow.onelink.me/1Nfg` (download redirect) | `#download` — differs | Original generated links include per-visit attribution; clone uses its own download/source-build handoff, without original tracking IDs |
| YouTube: Wispr AI channel | missing | E10: no corresponding clone channel established; do not impersonate the original account |
| Crunchbase: `wispr-ai` | missing | E10: no clone company profile established |
| Instagram: `wisprflow` | missing | E10: no corresponding clone account established |
| X: `wisprflow` | missing | E10: no corresponding clone account established |
| LinkedIn: `wisprflow` | missing | E10: no corresponding clone company page established |
| `https://ipinfo.io/` (pricing attribution) | absent | Original pricing credits this service; clone has fixed USD reference rates and does not use its location service |

## Justified constraints and proposed exceptions

These document constraints, not a blanket waiver for unfinished work. Outstanding bugs/missing implementations above must not be changed to `match` based on these entries.

- **E1 — proprietary appearance assets:** preserve original project art, icons, disclaimer and OFL Figtree/EB Garamond. Recreate layout, not Wispr source/art/audio models. Measurements still required.
- **E2 — customer evidence:** do not reuse Wispr customers/marks, invent clone customers, or present made-up testimonials. Use factual product capabilities until independently attributable clone feedback exists.
- **E3 — certifications:** do not imply SOC 2, HIPAA, ISO certification or enterprise guarantees for this project. Describe actual implementation instead.
- **E4 — privacy UI:** do not add a nonfunctional consent banner for visual similarity. First verify cookies, SDK traffic and storage, then provide controls the clone actually needs.
- **E5 — pricing/payment:** preserve the existing free clone and all payment behavior. Original paid-plan labels may be comparative only; do not create checkout, trial, billing or fake enterprise services.
- **E6 — providers:** existing Firebase email/password and Google must work. Apple, Microsoft and SAML require provider/tenant configuration; no credentials/configuration changes are authorized in this task. Disabled/clear unavailable states are preferable to misleading buttons. Exact provider parity needs a maintainer decision. The existing Firebase email/password setup sends verification/reset links, not the original email login-code flow; changing authentication protocols is outside this client recovery change.
- **E7 — transcription/polish:** Web Speech and deterministic cleanup are the implemented free browser alternative, not equivalent to Wispr models. Accuracy, correction semantics and unrestricted AI rewriting must be documented honestly. Browser recognition may use the browser vendor's server; never describe it as guaranteed local/offline.
- **E8 — operating-system integration:** browser shortcuts work while the page is focused, cannot reproduce global Fn hooks or insert into arbitrary desktop apps. Keep native app handoff available.
- **E9 — microphone/language support:** browser recognition support and device selection differ by engine. Detect capabilities, expose only working settings, and provide a typed practice fallback. Test real microphone permission and audio on a supported browser.
- **E10 — organization-only destinations:** merchandise, sales, hiring, affiliates and bounties cannot be fabricated. Proposed exception is a clear project information/support destination or omission, subject to maintainer review.

- **E11 — owner-requested identity:** use the supplied tombstone/X mark in the reference palette instead of any Wispr-style brand icon. This is an explicitly requested difference. Keep functional recording waveforms and third-party provider/OS logos; use a macOS template tint for the menu bar.

## Changes and verification ledger

### Account recovery

Draft PR: [#1](https://github.com/tommy-muckstack/wisprflowisdead/pull/1).

- Before: initial account could be displayed despite `hidden` because `.box` sets `display:grid`; network failures were treated as logged-out; DELETE failures were swallowed and redirected home.
- After: explicit hidden styling; visible loading status; retry on request/parse/server failure; redirect to login only for 401; show sign-out failure; lock duplicate DELETE; revalidate restored pages.
- `node --test site/tests/account.test.cjs`: **5 passed**. Tests exercise actual client code with mocked DOM/HTTP responses. This is not Firebase/browser end-to-end verification.
- `node --check site/wisprflowisdead/assets/account.js`: passed.
- `npm run lint` / `npm run build`: unavailable; baseline package has neither script. These are not reported as passed.
- Shared live auth smoke: attempted, blocked at Chromium launch before signup. Account cleanup: not applicable, no account created.
- Screenshots and score change: **unavailable, N/M → N/M**. Draft status required until browser/auth evidence is attached.

### Navigation proportions and behavior

Draft PR: [#2](https://github.com/tommy-muckstack/wisprflowisdead/pull/2), stacked on #1.

- Reference: user-provided desktop pair, original on the left. Visible differences: longer clone wordmark crowds the product switcher, injected Account/Sign out crowds the links, and the download CTA wraps.
- Use the compact, independent `FlowIsDead` label with the full `WisprFlowIsDead home` accessible name and existing project waveform. Keep the 912px navigation container and existing colors/type scale; do not copy the original wordmark.
- Home and pricing share non-shrinking logo/product/CTA sizing and a one-line download label. Desktop primary links remain Business, Pricing, Lab. Account access remains in the footer and the mobile menu; sign-out stays on the account page.
- At compact widths the product links move into the disclosure menu. The menu now works throughout 601–900px, exposes `aria-expanded`/`aria-controls`, closes on Escape, outside click, link selection, focus leaving the nav, or breakpoint change, and includes visible keyboard focus.
- Source syntax and whitespace checks passed. Real-browser sizing, focus behavior, screenshots and parity delta remain **unverified, N/M → N/M**. This change should remain a draft until those checks can run.
- The shared live auth smoke was attempted again for this PR and stopped at browser launch before navigation. No test account was created. Lint/build were also attempted again; both scripts remain absent.

### Browser dictation foundation

Draft PR: [#3](https://github.com/tommy-muckstack/wisprflowisdead/pull/3), stacked on #2.

- Before: browser account page offered a native download only. No browser transcription or cleanup flow existed.
- After: public `/demo` offers four writing contexts, editable/copyable output, language/style choices, and a speech state machine covering idle, permission request, listening, transcribing, polishing, result, cancellation, and recoverable error. The account page and marketing footers link to it.
- Web Speech is capability-checked and starts only on user interaction. Permission/network/device/language/no-speech errors, permission/stop timeouts, cancellation, page hiding, and late callbacks are handled. Partial text can be recovered into typed practice; it is never silently presented as a final transcript.
- Local English cleanup removes conservative fillers/repetitions and supports spoken punctuation, paragraph and bullet commands. URL/email/code literals remain intact. Four styles change capitalization/end punctuation only; they do not reproduce model rewriting. Other languages retain recognized text. E7–E9 apply.
- Drafts remain in page memory. No audio recording, transcript storage, service credentials, paid service, or new account requirement is introduced. The page discloses that browser speech services may send audio off device. Dictionary, snippets, history and persistent settings remain separate unfinished work.
- `npm run lint --prefix site` and `npm run build --prefix site`: passed. New dependency-free scripts parse JavaScript (including inline scripts) and check local asset paths. The site is deployed as source, with no bundler; these checks do not claim HTML/CSS visual or semantic validation.
- `npm test --prefix site`: **15 passed**, including the five account tests and ten speech/cleanup tests. Recognition events are injected, not real audio or browser permission tests.
- Shared live auth smoke was attempted before publication and failed at Chromium launch before navigation. No account was created. Screenshots and scores remain unavailable, **N/M → N/M**. This change stays a draft until live auth, browser, microphone and paired viewport checks pass.

### Login, signup and email recovery

Draft PR: [#4](https://github.com/tommy-muckstack/wisprflowisdead/pull/4), stacked on #3.

- Before: duplicate body markup, uncaught SDK/config failures, no retry or pending lock, password fields could be submitted inconsistently, session failure after account creation could trigger a second signup attempt, and return URLs accepted backslashes.
- After: explicit setup/loading/retry, native email/password validation, email correction, independent reset view, request locks, clear provider/network/error messages, signup-created confirmation with verification-link resend, and session retry without recreating the account. Successful sessions return to the account page or a validated local application route. The in-memory SDK is signed out after the server cookie is established.
- Signup confirms account creation separately from successful verification delivery. A failed name update or verification email does not imply account creation failed. Password reset uses a neutral response for unknown emails and does not describe a failed request as sent.
- The existing official Google SVG/font are retained. Scoped CSS restores the approved light button fill, border, type and spacing instead of the marketing cream override. Apple/Microsoft/SSO remain disabled with a visible configuration explanation (E6). Mobile card width, keyboard focus, hidden fields and no-JavaScript fallback are addressed; visual parity remains unverified.
- `npm run lint --prefix site`, `npm run build --prefix site`, and `git diff --check`: passed. `npm test --prefix site`: **25 passed**, including ten auth state/redirect/session-exchange regression tests. Firebase methods and fetch responses are mocked; these do not establish real signup, email delivery or Google OAuth success.
- Shared live smoke was attempted and stopped at the same Chromium Mach-port launch failure before navigation or account creation. Screenshots and scores remain unavailable, **N/M → N/M**. No secrets, Firebase provider settings, API payment behavior or cookie policy are changed.
- References: [Google button guidelines](https://developers.google.com/identity/branding-guidelines), [Firebase user management](https://firebase.google.com/docs/auth/web/manage-users), [Firebase session cookies](https://firebase.google.com/docs/auth/admin/manage-cookies).

### Tombstone branding

Draft PR: [#5](https://github.com/tommy-muckstack/wisprflowisdead/pull/5), stacked on #4.

- The owner supplied a tombstone with transparent X and explicitly requested it anywhere a Wispr-style icon would otherwise appear. Built-in imagegen created the green mark and lavender app tile. [Branding provenance and prompts](BRANDING.md) record source, palette, master assets, and packaging.
- Replaced header identity on home/pricing/login/demo, footer brand marks on home/pricing, and added the mark to account panels. All five pages reference the new 64px favicon and 180px Apple touch icon. The 1024px site icon uses the same app tile.
- Native Dock icon master, sidebar mark, welcome mark, and menu-bar icon use the tombstone. The resource bundle explicitly includes Branding; the menu bar uses a system template tint. Recording activity waveforms and third-party sign-in/OS icons remain functional symbols.
- `bash scripts/build-icons.sh`, shell/Swift syntax checks, website lint/build, **25 website tests**, and whitespace checks passed. PNG dimensions and alpha were checked; generated icon previews were inspected. `swift build` **passed** using cached FluidAudio dependencies, with pre-existing Combine/async-lock/resource warnings.
- macOS `iconutil` rejected both the new ten-size iconset and an identical control built from the previous icon. Escalation did not change the result. Final ICNS/Dock/menu-bar appearance is therefore not verified in this environment; no installed app was modified.
- Shared live auth smoke was attempted before publication and again failed at Chromium launch before navigation/account creation. Browser screenshots/computed styles and parity remain **N/M → N/M**. The app-icon asset previews are not website screenshots; E11 is the requested identity exception.

### Personal dictionary and snippets

Draft PR: [#6](https://github.com/tommy-muckstack/wisprflowisdead/pull/6), stacked on #5.

- Before: personal words and snippets existed only in the native app. Browser dictation could not apply or manage them.
- After: the demo offers personal word/correction and snippet CRUD, search, alphabetical/newest/oldest sorting, dictionary stars, native form validation, plain-text expansion counts, keyboard tabs, save/cancel, delete confirmation and visible empty/error states. Duplicate phrases are rejected across both lists.
- Recognition and typed practice use the same library snapshot. Longest whole-phrase matches win; expansion is nonrecursive and literal. Saved casing/line breaks and angle-bracket text survive cleanup. URLs, email, inline code and contractions are protected. Snippets spoken alone return their saved text exactly.
- Entries are page-only by default. Explicit opt-in saves to the single `wisprflowisdead.library.v1` localStorage key. Clear/delete failures are surfaced; failed writes preserve previous data. Cross-tab conflicts prompt reloading instead of silently overwriting, and unreadable saved data is preserved until explicitly cleared. The UI explains that saved data is available to everyone using that browser profile.
- Limits and remaining differences: post-recognition replacements cannot train or bias the browser service; automatic learning is not implemented. The browser library is personal, local, plain-text and capped at 1,000 entries; it has no account/team sync, rich-text paste, import, or bulk selection. These gaps remain `differs`; they are not silently counted as a match. Free browser replacements are covered by E7/E9.
- Website lint/build and whitespace checks pass. **35 tests pass**, including ten library validation/storage/matching tests. A source integration check confirms demo/library DOM IDs resolve without duplicates. Neither check establishes rendered controls, actual localStorage behavior in all engines, microphone results, or focus behavior.
- The shared smoke2 implementation was attempted with a cleanup wrapper for its own throwaway account. Chromium failed at the same Mach-port launch step before navigation or account creation; cleanup was not needed. Screenshots, computed styles and scores remain **N/M → N/M**.
- References: [dictionary behavior](https://docs.wisprflow.ai/articles/4052411709-teach-flow-your-words-with-the-dictionary), [snippets](https://docs.wisprflow.ai/articles/5784437944-create-and-use-snippets), [library management](https://docs.wisprflow.ai/articles/9639977157-view-shared-dictionary-words-and-snippets-in-the-admin-portal). These supplied behavior evidence, not screenshots or proprietary implementation.

### Home content and accessibility

Draft PR: [#7](https://github.com/tommy-muckstack/wisprflowisdead/pull/7), stacked on #6.

- Before: anonymous first-person statements resembled customer testimonials; speed figures and a 100+ language promise lacked evidence for this clone. Minimum OS copy disagreed with `Package.swift`/README. Privacy copy could be mistaken for the browser demo's behavior.
- After: factual product cards replace implied testimonials, unsupported speed/language claims are removed, Mac requirements say 14.2+, and copy distinguishes local Mac processing from browser speech services. Native Apple/Qwen3 English configuration and model-dependent rewriting are described accurately. These intentional content differences implement E2/E3/E7/E9; no customers or benchmarks were invented.
- Style previews have linked tab/panel roles, selected state, a single tab stop, arrow/Home/End navigation, and visible focus. A skip link and main landmark improve navigation. All previews remain readable without JavaScript.
- Feature panels flow in document order when JavaScript is unavailable, reduced motion is requested, the viewport is at most 600px wide, or at most 720px high. This avoids an absolute, clipped panel on small screens. Desktop scrolling is animation-frame scheduled and updates after resize/page restoration. Exact original scroll timing and mobile geometry remain unverified differences.
- Website lint/build, whitespace checks and all **35 existing tests** pass. Source checks confirm unique IDs and resolved ARIA references. No new implementation-mirroring tests were added for this content/CSS change; these checks do not verify rendered layout, assistive technology or focus behavior.
- Shared live smoke2 with throwaway-account cleanup was attempted again and failed at Chromium launch before navigation. No account was created. Before/after screenshots, computed styles and scores remain **N/M → N/M**; this change remains a draft.
- References: native `Transcription.swift`, `TransformRunner.swift` and package platform requirement; [WAI tabs pattern](https://www.w3.org/WAI/ARIA/apg/patterns/tabs/). The original homepage remains the comparison target, not evidence for clone performance claims.

### Pricing interactions and comparison clarity

Draft PR: [#8](https://github.com/tommy-muckstack/wisprflowisdead/pull/8), stacked on #7.

- Before: $0 cards listed unbuilt team/compliance features, billing selection changed styling only, the Notetaker control was decorative, mobile comparison hid Enterprise, desktop FAQ questions were clipped, and calculator output accepted negative/nonfinite inputs and rounded hours before annualizing.
- After: introductory/card/table context clearly describes Wispr Flow reference plans, not clone entitlements. Reference rates checked on 2026-10-15 update together in cards and table for annual/monthly billing and the Growth Notetaker option. Clone CTAs still lead to its existing free flow; the mislabeled sales link says project support. No checkout, trial, subscription, API, secret or payment behavior changed (E5).
- Mobile feature disclosures have stable targets, accurate expanded labels, preserved state across breakpoint changes and a readable no-JavaScript fallback. The comparison has 34 five-column semantic rows, accessible included/not-included values and a keyboard-focusable horizontal region exposing Enterprise on mobile. These layout changes await visual comparison.
- Calculator inputs reject blank, nonfinite, negative and out-of-range values (0–24 hours/day; $0–$100,000/hour), show errors and suppress invalid results. Valid fractional hours are preserved before annualization. Visible assumptions are 22 workdays/month and 50% less typing time; output is hypothetical time value, not a clone performance claim or guaranteed cash savings.
- FAQ answers are present in HTML. Desktop questions form a scrollable vertical tab list with arrow/Home/End navigation; mobile questions are expandable headings with linked panels. All answers remain readable without JavaScript. Focus is recovered when breakpoint changes hide the active answer. The remaining W avatar was replaced with the owner’s tombstone mark.
- Website lint/build and whitespace checks pass. **39 tests pass**, including four pricing calculation/reference-rate tests. A source check validates balanced markup, unique IDs, resolved ARIA references and the five-column rows. These are not browser interaction, screen-reader or visual tests.
- The required shared smoke2 flow was attempted with cleanup and again failed at Chromium launch, before navigation or account creation. Screenshots, computed styles and parity remain **N/M → N/M**. The draft must still pass live auth and paired 1440/390 captures; reference pricing may change and must be rechecked before publication.
- References: [original pricing](https://wisprflow.ai/pricing), [WAI tabs](https://www.w3.org/WAI/ARIA/apg/patterns/tabs/), [WAI accordions](https://www.w3.org/WAI/ARIA/apg/patterns/accordion/). The source contains apparent differences between card and table free-plan limits; this change labels them as reference content and does not invent clone limits.

### Browser history and retention

Draft PR: [#9](https://github.com/tommy-muckstack/wisprflowisdead/pull/9), stacked on #8.

- Before: completed browser dictations and typed practice had no history list or recovery after changing drafts.
- After: Recent activity stores each completed result once, with original words, language/style/context and timestamp. It offers search, copy, full-text inspection, restore-result/restore-original with overwrite confirmation, individual deletion and clear-all. Restoring is disabled during recording/cleanup. Text is rendered literally; no user content is inserted as HTML.
- Default history exists only in page memory. Explicit choices save text for 24 hours or until deleted, or remember a disabled-history preference with no transcripts. Changing to page-only removes the saved copy. The feature owns only `wisprflowisdead.history.v1`; dictionary/snippet data and unrelated applications are untouched. No audio is recorded or retained by this feature.
- Expiry is enforced on load, once per minute while open, and on foreground/page restoration. A browser page cannot delete storage while closed; the UI discloses this. Expired entries stay hidden when physical removal fails, and deletion is retried. Failed writes/deletes do not report success; the current result stays in the editor, and the latest failed history save can be retried. Known cross-tab changes prevent stale writes and refresh the visible saved history. Unreadable saved data is preserved until explicitly cleared.
- Bounds: 200 entries, 200,000 characters each for result/original, and a 4,000,000-character saved payload. Reaching a bound shows an error instead of silently dropping earlier results. Browser storage can impose a smaller limit. Preferences requiring storage cannot be saved when the browser blocks it; page-only history remains available.
- Remaining differences: this public demo's history belongs to a browser profile, not an authenticated account; signing out does not clear it, and the UI states how to clear it. Original account-linked cleanup/sync needs a separate decision/implementation. Audio playback and recognition retry from retained audio are unavailable because Web Speech does not supply a retained recording (E7/E9). Original default storage and precise native Hub layout are not matched.
- Website lint/build, whitespace and source integration checks pass. **49 tests pass**, including ten history validation/storage/expiry/conflict tests. These validate deterministic logic, not actual browser persistence, privacy permissions, microphone capture or native history parity.
- Shared live smoke2 with cleanup was attempted and failed at Chromium launch before navigation; no account was created. Website screenshots, computed styles and parity remain **N/M → N/M**. The change remains a draft pending browser, live auth and microphone verification.
- References: [original history deletion and retention](https://docs.wisprflow.ai/articles/4465314211-delete-transcripts-and-history-in-wispr-flow), [original data-sharing/local-history controls](https://docs.wisprflow.ai/articles/9609615338-private-cloud-sync-and-data-sharing-preferences-in-wispr-flow).

### Browser settings and microphone check

Draft PR: [#10](https://github.com/tommy-muckstack/wisprflowisdead/pull/10), stacked on #9.

- Before: only inline language/style controls and a fixed Ctrl+Alt+Space toggle were available. There was no microphone check, shortcut customization or settings persistence.
- After: a native modal dialog offers synchronized language/style controls, one custom Ctrl+Alt+(optional Shift)+letter/number/Space shortcut, keyboard enable/disable, and hold-to-talk or press-to-toggle activation. Key release stops a held dictation even after modifier release; repeats, composing text and AltGraph do not trigger recording. Closing/cancelling/hiding the page releases active checks. Browser timer/frame callbacks use wrappers so they do not receive a controller object as their host receiver.
- Settings apply only to the page by default. Explicit opt-in writes only `wisprflowisdead.preferences.v1`; reload/reset, corrupt data, known cross-tab changes, failed writes and failed removal have visible states. A failed saved update preserves both active and saved settings. Errors from inline selectors are visible outside the modal too. Reset leaves history/library/account data unchanged.
- The microphone check requests the browser default input only on a button click, displays its reported label and measured input level, and stops after 20 seconds. Permission/setup has a 15-second timeout. Cancelling a pending request closes any late-granted stream; disconnects, permission failures and processing errors release tracks, frames and audio context. It does not record, upload or play audio through speakers.
- Remaining differences: browser/system settings select dictation input; the local test does not claim it can force the speech service to use that device. Global/Fn/mouse/multiple native bindings and automatic multilingual recognition are not provided. Web Speech track-input support is not assumed across browsers. E8/E9 apply; real permission prompts, input levels, native dialog focus and hold behavior still require browser testing.
- Website lint/build, whitespace and source integration checks pass. **64 tests pass**, including eight preference/shortcut tests and seven microphone lifecycle tests. Audio streams, permissions and levels are injected in those tests; no real microphone or browser interaction pass is claimed.
- Shared smoke2 with cleanup was attempted again and failed at Chromium launch before navigation/account creation. The in-app Node REPL/browser execution tool is still unavailable. Screenshots, computed styles and scores remain **N/M → N/M**; this change is a draft.
- References: [original shortcut controls](https://docs.wisprflow.ai/articles/2612050838-Supported-%26-Unsupported-Keyboard-Hotkey-Shortcuts), [original microphone controls](https://docs.wisprflow.ai/articles/8884408990-connect-and-set-up-external-audio-devices), [getUserMedia](https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia), [SpeechRecognition input](https://developer.mozilla.org/en-US/docs/Web/API/SpeechRecognition/start).

### Browser onboarding

Draft PR: [#11](https://github.com/tommy-muckstack/wisprflowisdead/pull/11), stacked on #10.

- Before: new visitors went directly into a demo with no setup guidance or connection between permission, language/shortcut settings and practice.
- After: an optional four-step guide covers browser speech privacy, microphone input, preferences and practice. Microphone testing opens the real Settings check; only detected input level marks that step complete. Practice completion comes from a successful dictation or typed cleanup with nonempty original/result text. There is no seeded recording or fabricated result.
- Back/continue, individual skip, skip-all and reopening are available. Skipped steps are labeled separately from completed checks. Unsupported microphone/speech capabilities direct users to skipping or typed practice. Recording locks guide navigation; explicit navigation moves focus to the step heading, and practice actions focus the actual editor/controls. Reopening an already-visible guide preserves its current progress.
- Finishing/skipping remembers only `{version, status}` under `wisprflowisdead.onboarding.v1`, so the guide does not repeatedly interrupt returning visitors. It stores no profile, audio or transcript data. A failed write finishes this visit while visibly explaining that the choice could not be remembered. Corrupt/unknown saved flags remain intact until an explicit completion action. Setup can always be reopened from the header.
- Remaining differences: this is an inline browser guide, not an OS installer or native first-run window. It does not request desktop Accessibility/keyboard-extension permissions, perform original-account onboarding, or collect unused profile/work questions. Native global shortcuts, automatic language detection and device selection remain E8/E9. Browser focus, responsive layout and actual microphone onboarding still need hands-on comparison.
- Website lint/build, whitespace and source integration checks pass. **70 tests pass**, including six setup progression/skip/persistence tests. The checks do not establish real permission prompts, audio levels, screen-reader flow or screenshot parity.
- Shared smoke2 with cleanup was attempted and stopped at the Chromium launch error before navigation/account creation. Launch Services also could not start the isolated Chrome fallback. Screenshots, computed styles and scores remain **N/M → N/M**; this change remains a draft.
- Reference: [original first-dictation setup](https://docs.wisprflow.ai/articles/3152211871-setup-guide). Native permission/account steps are recorded as differences rather than simulated in the browser.

### Browser command mode

Draft PR: [#12](https://github.com/tommy-muckstack/wisprflowisdead/pull/12), stacked on #11.

- Before: every spoken input was inserted as dictation; there was no instruction mode or selection-based edit. Browser command mode was missing.
- After: an explicit, off-by-default mode reuses recording, hold/toggle shortcuts and typed input for six local commands: uppercase, lowercase, bullet list, numbered list, trim spacing and cleanup. A selected passage is captured before recognition; no selection targets the whole editor. Empty targets are rejected before requesting the microphone. A visible hint states the replacement scope.
- Commands use a finite English phrase list. Unsupported/ambiguous instructions, empty results and size limits show an error and preserve the draft. Lists use existing nonempty lines; numeric values and surrounding text remain intact. Case changes intentionally include links/code and are labeled accordingly. Cleanup follows the chosen language/style and existing literal protections, without snippet expansion.
- Replacement adds no dictation boundary spaces, including within a word. The changed passage stays selected; Undo edit restores the complete pre-command draft. Error recovery returns spoken instructions to the command field rather than typed dictation. Cancellation, processing locks and stale recognition events reuse the existing lifecycle. Command success does not falsely complete the onboarding dictation step.
- Command history records the original selected passage, result and instruction under the same retention setting. Search includes instructions; original/result restore and deletion remain available. Existing dictation history stays readable. History is still browser-profile data, not account-linked.
- Remaining differences: no arbitrary AI rewrite, reply drafting, translation, external search/app generation, native global/multiple shortcut bindings or native notice/Hub layout. Commands are free and do not reproduce paid-plan gating (E5/E7/E8/E9). Real speech, selection persistence across focus changes, mobile layout and assistive-technology behavior still need browser checks.
- Website lint/build and whitespace checks pass. **78 tests pass**, including seven command tests and one command-history regression test. These cover partial-word/Unicode replacement, undo snapshots, numeric list items, language/literal safeguards, invalid/oversized instructions, lifecycle errors/retry/cancellation and history reload. They do not establish rendered interaction parity.
- Shared smoke2 with cleanup was attempted again; Chromium failed at `bootstrap_check_in ... MachPortRendezvousServer` before navigation/account creation. No test account exists to delete. The parity CLI was also attempted against live at both requested widths and stopped on missing `playwright` dependency. Screenshots, computed styles and score change remain **N/M → N/M**; this change remains a draft.
- Reference: [original command mode](https://docs.wisprflow.ai/articles/4816967992-how-to-use-command-mode), checked 2026-10-15. Original cloud-model behavior and plan access are recorded as differences, without initiating a trial.

### App bundle entry point

Draft PR: [#13](https://github.com/tommy-muckstack/wisprflowisdead/pull/13), stacked on #12.

- GitHub Actions provides an independent working macOS/Linux environment. [CI run 38786413225](https://github.com/tommy-muckstack/wisprflowisdead/actions/runs/38786413225) built Swift and passed all 43 native tests, but failed before app assembly because `scripts/run-dev.sh` was not executable.
- The original tree records this script as `100755`; the branding PR's remote file update accidentally recorded `100644`. This change restores the executable bit without changing the script contents. The original executable mode of `scripts/sync-design.sh` remains intact remotely; `build-icons.sh` is intentionally invoked through Bash.
- [Fresh CI run 38787305059](https://github.com/tommy-muckstack/wisprflowisdead/actions/runs/38787305059) passed macOS build/test/app assembly and Linux tests. App assembly includes PNG resizing, ICNS conversion and ad-hoc signing. Dock/menu-bar visual inspection remains outstanding; native build success is not website evidence.
- Website lint/build and all 78 tests pass before the PR. Shared smoke2 remains blocked locally before browser navigation/account creation; no account was created. Visual scores and screenshots for this change remain N/M.

### Hosted website verification

Draft PR: [#14](https://github.com/tommy-muckstack/wisprflowisdead/pull/14), stacked on #13.

- Before: the parity CLI and browser checks could not run in this Mac environment; the repository CI only built/tested the native application.
- After: a separate Ubuntu workflow installs the pinned shared parity toolchain/Chromium, checks the site, and captures original, live deployment and PR-head candidate home/pricing/login at both required widths. Shared parity scores and computed styles are uploaded with raw viewport captures and a navigation/footer inventory. The workflow records source/tool commits and reuses valid original screenshots for the candidate comparison.
- The candidate server is read-only and serves only public website files plus the fixed public config endpoint. It forwards no cookies/auth headers and has no repository/deployment secrets. Session GET returns 401; writes return 405. This is an anonymous visual preview and explicitly cannot prove authentication or Vercel function behavior.
- The gate fails on capture errors, non-200 parity pages, scores below 90 or horizontal overflow. Artifacts upload even after failed measurements. Raw images retain cookie/animation states hidden by the shared script, so the score is not treated as evidence for those states. Visual/interaction review remains required even if scores pass.
- Local website lint/build and 78 tests pass; QA scripts parse and whitespace checks pass. Shared smoke2 remains blocked locally before navigation/account creation. The first hosted run completed actual captures/styles and exposed lower scores across the stack, plus a 732 px-wide candidate pricing page at the 390 px viewport. Those regressions require correction, not a threshold waiver.
- The next workflow revision adds real browser interaction checks for mobile navigation, pricing and typed demo/library/command/history/settings flows. It also archives public viewport screenshots and JSON reports on a separate `qa/parity-evidence-<run>-<attempt>` branch. Only the archive job has repository write permission; it never updates main or the PR branch and does not run on fork PRs. [Run 38790232733](https://github.com/tommy-muckstack/wisprflowisdead/actions/runs/38790232733) completed and archived the evidence successfully. Five of six browser groups passed: navigation and typed demo flows at both widths, plus desktop pricing. Mobile pricing failed immediately on 732 > 390 px horizontal overflow, so its remaining controls were not tested in that run. The six page scores reproduced the first run exactly. No auth/audio pass is implied. Full instructions and evidence limits are in `qa/README.md`.

### Pricing responsive layout

Draft PR: [#15](https://github.com/tommy-muckstack/wisprflowisdead/pull/15), stacked on #14.

- Before evidence: [original mobile](https://github.com/tommy-muckstack/wisprflowisdead/blob/qa/parity-evidence-38790232733-1/docs/parity/38790232733-1/raw/original-pricing-390.png), [candidate mobile](https://github.com/tommy-muckstack/wisprflowisdead/blob/qa/parity-evidence-38790232733-1/docs/parity/38790232733-1/raw/candidate-pricing-390.png), [browser failures](https://github.com/tommy-muckstack/wisprflowisdead/blob/qa/parity-evidence-38790232733-1/docs/parity/38790232733-1/behavior/report.json). Pricing baseline is **57.0 desktop / 59.3 mobile**, with 732 px content width at a 390 px viewport.
- Restores the measured 48 px mobile title, -0.05em title tracking, 14/16 px mobile/desktop billing controls and mobile rounded plan labels. Shorter, truthful introductory copy retains the distinction between reference plans and the free clone. Reference rate details remain visible after the cards, within the existing separation before the availability panel.
- Mobile comparison returns to feature labels above plan values. Three plan columns fit the region; Enterprise remains reachable by scrolling the fourth column. The scroll region now contains positioned accessibility labels, preventing them from escaping to the page containing block. The hosted rerun confirms that page overflow is eliminated at both widths and the Enterprise column is reachable.
- Browser checks now emulate touch/mobile contexts and test Enterprise reachability. Mobile pricing controls run before the final overflow assertion, so an overflow failure no longer prevents billing/ROI/FAQ/card coverage. Raw pricing captures now also preserve full-page images for section review.
- Local lint/build and all **78 tests pass**; QA script syntax and whitespace checks pass. Shared smoke2 with cleanup was attempted inside and outside the sandbox and failed before navigation on Chromium's MachPortRendezvousServer error. No account was created. No auth, audio or 90+ visual pass is claimed.
- [Hosted run 38792121104](https://github.com/tommy-muckstack/wisprflowisdead/actions/runs/38792121104), product commit `27a3e3fdb8e644e1ade10ce53dcc7c02f37b8216`: **all six interaction groups pass**, with no application JS errors. Mobile billing/add-on prices, ROI validation/results, FAQ/card expansion and Enterprise scroll reachability now execute successfully. The shared parity report confirms no horizontal overflow on any captured page. The workflow still fails the unchanged 90+ visual gate.
- Measured pricing scores: **57.0 → 67.9 desktop (+10.9)** and **59.3 → 59.5 mobile (+0.2)** versus the preceding candidate run; production remains 75.0/75.1. Original dimensions are unchanged between these runs. Current pricing height is 9,237 vs original 9,196 px on desktop and 11,321 vs original 11,193 px on mobile. These are progress measurements, not parity acceptance.
- After images: [desktop](https://github.com/tommy-muckstack/wisprflowisdead/blob/qa/parity-evidence-38792121104-1/docs/parity/38792121104-1/raw/candidate-pricing-1440.png), [mobile](https://github.com/tommy-muckstack/wisprflowisdead/blob/qa/parity-evidence-38792121104-1/docs/parity/38792121104-1/raw/candidate-pricing-390.png), [full mobile](https://github.com/tommy-muckstack/wisprflowisdead/blob/qa/parity-evidence-38792121104-1/docs/parity/38792121104-1/raw/candidate-pricing-390-full.png). Matching original/live captures, computed styles, behavior report and scores are preserved in the same evidence directory. Original/candidate desktop and mobile pricing viewports were visually reviewed: mobile title is now 48 px at y=136 and the first card starts at y=434 (original y≈435), with its CTA at y≈592 in both. Remaining differences include desktop decorative art, plan typography/default add-on state, and comparison/FAQ section spacing. Mobile security starts about 202 px below its original position; this is not waived.
- [Native CI 38792121357](https://github.com/tommy-muckstack/wisprflowisdead/actions/runs/38792121357) also passed macOS build/test/app assembly and Linux tests.
- Additional audit observation: the earlier raw candidate login screenshot shows its initial loading state. Login's ready/error states need explicit captures; its page score is not proof of a ready authentication form.

### Hosted authentication verification

Draft PR: [#16](https://github.com/tommy-muckstack/wisprflowisdead/pull/16), stacked on #15.

- Before: the working hosted browser job checked anonymous pages and typed product flows only. Local smoke2 could not launch a browser, so no signup/session/sign-out pass was established. The raw candidate login capture showed initial SDK loading.
- Adds execution of the pinned shared smoke2 flow against the live frontend and PR frontend. For the latter, Playwright replaces public HTML/assets on the deployed origin while leaving all Firebase/session requests live. No API, payment, deployment-secret or provider configuration changes are made. Each flow uses its own generated throwaway credentials, never a personal session or original-site SSO.
- Strengthens the smoke's cookie-presence result with matching server identity and Secure/HttpOnly/SameSite cookie checks after signup/login, then a 401 and absent cookie after each UI sign-out. Account screenshots at both widths mask the throwaway identity. Passwords, tokens and cookie/storage state are kept out of artifacts.
- Cleanup is attempted after success or failure before closing the browser, with three attempts and explicit email/UID ownership checks before deletion. The gate requires deletion and session cleanup to succeed. Active workflow runs are no longer cancelled automatically by a newer commit, allowing cleanup to finish. Runner loss/manual cancellation remains a cleanup limitation; failures require follow-up and are never treated as success.
- The shared template fingerprint and generated module syntax are checked before browser execution. The example.com test mailbox cannot receive email; verification/reset delivery and original email-code signup remain untested. Candidate frontend/live backend checks also do not prove candidate Vercel routing or response headers.
- Local lint/build and all **78 website tests pass**. The pinned shared template blob matches the configured upstream commit; hook guards/generated-module syntax and QA syntax/whitespace checks pass. Running the new smoke wrapper inside and outside the sandbox still fails at browser launch before navigation; those local attempts created no account.
- [Hosted run 38794977597](https://github.com/tommy-muckstack/wisprflowisdead/actions/runs/38794977597), commit `742b8698e9e2e6ec00f2338eeb2afa58781c19ec`, verifies **signup → sign-out → login → sign-out on both frontends**, with no JS errors or smoke notes. Matching server identities and Secure/HttpOnly/SameSite=Lax cookies pass after signup/login; 401 and absent cookies pass after each UI sign-out. Both reports explicitly record `account: deleted` and `session: cleared`: [live report](https://github.com/tommy-muckstack/wisprflowisdead/blob/qa/parity-evidence-38794977597-1/docs/parity/38794977597-1/auth/live.json), [candidate report](https://github.com/tommy-muckstack/wisprflowisdead/blob/qa/parity-evidence-38794977597-1/docs/parity/38794977597-1/auth/candidate.json). Two test accounts were created and deleted; none remain from this run.
- Masked candidate account screenshots were captured after signup and login at both widths; [mobile after login](https://github.com/tommy-muckstack/wisprflowisdead/blob/qa/parity-evidence-38794977597-1/docs/parity/38794977597-1/auth/candidate-account-login-390.png) was visually reviewed. This establishes account rendering, not parity with the original account UI.
- All six anonymous interaction groups pass again. [Native CI 38794977510](https://github.com/tommy-muckstack/wisprflowisdead/actions/runs/38794977510) passes macOS build/test/app assembly and Linux tests.
- Raw clone login captures confirm enabled Continue on both widths after SDK setup. Shared scoring waits 26 seconds on both sites and archives its exact config and scored PNGs. Candidate login remains **78.1 desktop / 67.5 mobile**; home remains 79.0/56.9 and pricing 67.9/59.5. The wait is a measurement-protocol change, not a product improvement, and no score gain is claimed.
- The raw-capture stage initially timed out because it waited for an enabled Continue control. The original keeps that control disabled while email is empty. The corrected read-only check records the original's visible, editable email field separately from clone SDK readiness, without submitting or claiming original authentication readiness. [Follow-up run 38797010581](https://github.com/tommy-muckstack/wisprflowisdead/actions/runs/38797010581) has **no capture errors** and passes all six interaction groups plus both auth smokes again. Both additional disposable accounts were deleted and sessions cleared. Scores remain unchanged; only the 90+ visual gate fails. Its [control inventory](https://github.com/tommy-muckstack/wisprflowisdead/blob/qa/parity-evidence-38797010581-1/docs/parity/38797010581-1/raw/inventory.json) records the original's disabled initial submit control; candidate initially permits Continue and relies on native email validation, a remaining behavior difference.
- The browser navigation/footer inventory also adds the previously omitted Lab, download redirect, social/company destinations and pricing location-service attribution above. These are documented gaps/exceptions, not working clone routes.

### Login card geometry

Draft PR: [#17](https://github.com/tommy-muckstack/wisprflowisdead/pull/17), stacked on #16.

- Before: [desktop comparison](https://github.com/tommy-muckstack/wisprflowisdead/blob/qa/parity-evidence-38794977597-1/docs/parity/38794977597-1/candidate/login-1440-side.png), [mobile comparison](https://github.com/tommy-muckstack/wisprflowisdead/blob/qa/parity-evidence-38794977597-1/docs/parity/38794977597-1/candidate/login-390-side.png). Baseline login scores are **78.1 / 67.5**. Original computed styles show the card content at x=480/67, y=192, with 48/32 px headings and -0.05em tracking. The original card starts at y=160; its mobile width is 320 px, compared with the candidate's 358 px.
- Restores the measured card placement, 32 px inset, 32/16 px desktop/mobile corners, heading metrics, 52 px provider rows, 38 px email input and form spacing. The initial email label remains accessible while visually hidden, matching the placeholder-led reference; later steps retain visible labels. Empty status text no longer reserves a blank row.
- Shortens the initial signup action to "Create an account" so signup and reset remain reachable in the card's lower space. Name/password/signup confirmation/reset/error states remain naturally sized; no fixed height clips longer states. The user-requested tombstone stays in the logo, with the same FlowIsDead label as the marketing navigation.
- Google keeps its standard multicolor G, fixed 20 px logo, white fill, gray 1 px border, Google Sans Medium and 12/10 px padding/gap. It uses a rectangular 52 px container for equal prominence alongside the provider rows. The reference's cream fill/black border/Figtree treatment is not reproduced because the task also requires [Google's branding guidelines](https://developers.google.com/identity/branding-guidelines), checked 2026-10-15. Apple/Microsoft/SSO stay disabled, with a concise visible availability explanation (E6). Project art and truthful compatibility text remain E1/E2/E11.
- Local lint/build and all **78 tests pass**. Whitespace and script syntax pass. Required smoke2 was attempted inside and outside the sandbox; Chromium stopped before navigation and created no account in those local attempts.
- [Hosted run 38797508456](https://github.com/tommy-muckstack/wisprflowisdead/actions/runs/38797508456), product commit `a155b9138506b8660ea6b5831d36237d9d152601`, passes both live/candidate signup → sign-out → login → sign-out smokes, all server identity/cookie checks, and both account deletions/session cleanups. Both reports have no notes or JS errors: [live](https://github.com/tommy-muckstack/wisprflowisdead/blob/qa/parity-evidence-38797508456-1/docs/parity/38797508456-1/auth/live.json), [candidate](https://github.com/tommy-muckstack/wisprflowisdead/blob/qa/parity-evidence-38797508456-1/docs/parity/38797508456-1/auth/candidate.json). All six anonymous interaction groups pass, with no capture errors or page overflow. All six disposable accounts across the three auth runs inspected so far were deleted.
- Measured login scores improve **78.1 → 93.6 desktop (+15.5)** and **67.5 → 91.9 mobile (+24.4)** against the prior candidate using the same capture protocol. Both exceed 90. Home 79.0/56.9 and pricing 67.9/59.5 remain unchanged, so the overall workflow correctly still fails the visual gate.
- After screenshots were visually reviewed: [desktop pair](https://github.com/tommy-muckstack/wisprflowisdead/blob/qa/parity-evidence-38797508456-1/docs/parity/38797508456-1/candidate/login-1440-side.png), [mobile pair](https://github.com/tommy-muckstack/wisprflowisdead/blob/qa/parity-evidence-38797508456-1/docs/parity/38797508456-1/candidate/login-390-side.png), [raw settled mobile](https://github.com/tommy-muckstack/wisprflowisdead/blob/qa/parity-evidence-38797508456-1/docs/parity/38797508456-1/raw/candidate-login-390-settled.png). Computed heading positions/metrics now match: x=480/67, y=192, 48/32 px font, 52.8/35.2 px line height and -2.4/-1.6 px tracking. Provider rows start at y=275/257 and are 52 px high; Continue is at y=644/626, matching the reference.
- This does not establish complete auth parity: original email-code signup, delivery/reset links, OAuth, unavailable providers and later-state visual comparison remain outstanding. Whole-page login heights are 982/968 vs original 1096/1095; the score covers only the initial viewport. Footer customer marks are deliberately replaced with truthful compatibility text, and project art/identity differ under E1/E2/E11. Initial Continue validation also still differs as recorded above.
- [Native CI 38797508560](https://github.com/tommy-muckstack/wisprflowisdead/actions/runs/38797508560) passes macOS build/test/app assembly and Linux tests.

## Next verification gates

1. Run and inspect the hosted browser workflow; download artifacts and validate that captures show the intended pages. Restore interactive/local browser access for the flows the read-only capture cannot verify. Supply environment through the existing deployment workflow, never a committed .env file.
2. Capture original/live baseline at 1440 × 900 and 390 × 844, plus menus, hover/focus, scroll and cookie states excluded by parity.mjs. Save computed styles alongside paired images.
3. Create dedicated email-only free test accounts where eligible, run signup → sign-out → login → sign-out, then delete those accounts. Do not use existing personal sessions, SSO on the original, trials or payment details.
4. Complete remaining logical PR areas, append measured before/after evidence for each, and rerun smoke per PR. No merge is authorized.
5. Home/pricing/login must each reach 90+ at both widths; all matrix items need a verified match or an explicitly justified exception. Current state does not satisfy this gate.
