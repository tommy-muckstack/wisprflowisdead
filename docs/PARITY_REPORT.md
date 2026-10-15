# WisprFlowIsDead parity report

Audit date: 2026-10-15. Upstream baseline: `71e3e684ff333da4732ad92da5347d446e9feec7`.
Scope: marketing website, shared Firebase account flow, and a browser dictation experience. The native Swift app is a separate, existing implementation.

**Not complete. No visual parity score or live authentication pass has been established in this audit.**

## Evidence and environment

- Read the repository README, website README, existing product spec, upstream contributing guide, and shared parity/smoke scripts. No repository AGENTS.md or .env.example exists at the baseline.
- Git cloning failed with DNS errors even with escalation. Retrieved 78 files through the GitHub connector and verified each Git blob SHA against the pinned tree. Two native-only TTF files were not retrieved; all website files and fonts are present. The local import commit is not an upstream commit and must not be pushed as the PR base.
- `site/` is the Vercel project root; functions are in `site/api/`. At baseline only home, pricing, login, and app HTML routes exist; the browser dictation change adds `/demo`. There are no website lint/build/test scripts at baseline.
- Public text/navigation inspected on [home](https://wisprflow.ai), [pricing](https://wisprflow.ai/pricing), [get started](https://wisprflow.ai/get-started), and the [help center](https://docs.wisprflow.ai). This is source/text evidence, not a rendered-browser comparison. Responsive nav menus, hover states, and current computed styles remain unobserved.
- No reference captures at `/workspace/isdead-shots/parity/wisprflowisdead/`. The local in-app browser execution tool is unavailable. Standalone Playwright Chromium fails at launch with macOS `bootstrap_check_in ... MachPortRendezvousServer` permission errors, including escalated attempts.
- The user subsequently supplied a paired desktop screenshot (`image (10).png`, original left, clone right) and prioritized the navigation bar. It is useful reference evidence, but its two panels do not establish equal viewport widths or a measured parity score. Installed Google Chrome was also attempted through Playwright and exited before navigation.
- `npm install` for both website and parity tooling fails with `ENOTFOUND registry.npmjs.org`. Website APIs cannot be exercised without dependencies/configuration. No environment values or secrets were read, changed, or committed.
- A static preview was started at `http://127.0.0.1:3300/wisprflowisdead/` after socket-binding approval. This Python fallback serves `.html` paths; it does not emulate Vercel clean URLs or functions.
- `scripts/parity.mjs --config parity/wispr.json --clone https://yourappisdead.com --viewports 1440x900,390x844` was attempted: missing package dependency prevents capture. `templates/smoke2.mjs https://yourappisdead.com/wisprflowisdead wispr-account` was attempted: browser launch fails before navigation. No accounts were created, so there are none to delete.
- An original desktop installation already exists. It was not launched or inspected, and no existing personal account was used. Original email signup, onboarding and free-plan eligibility still need hands-on checks; no SSO, paid trial or payment was used.

## Score ledger

`N/M` means not measured. User-provided approximate scores are historical context only, not measurements from this audit. Every row needs paired before/after captures and computed-style JSON at the stated viewport before a visual match can be claimed. Screenshots are currently unavailable for every row below.

| Page | Viewport | Historical context | Before | After | Screenshots |
|---|---|---|---|---|---|
| Home | 1440 × 900 | — | N/M | N/M | Blocked: browser/dependencies |
| Home | 390 × 844 | approximately 62, supplied in task | N/M | N/M | Blocked: browser/dependencies |
| Pricing | 1440 × 900 | approximately 76, supplied in task | N/M | N/M | Blocked: browser/dependencies |
| Pricing | 390 × 844 | — | N/M | N/M | Blocked: browser/dependencies |
| Login | 1440 × 900 | — | N/M | N/M | Blocked: browser/dependencies |
| Login | 390 × 844 | — | N/M | N/M | Blocked: browser/dependencies |

## Feature matrix

Status is `match`, `differs`, or `missing`. `Differs` includes implementations awaiting comparison; it does not mean that a fix was visually verified. Severity: P0 blocks the requested core experience; P1 breaks an important flow; P2 is a noticeable presentation/accessibility gap. The evidence column names source files or tests; **all screenshot/score entries remain N/M** until capture is restored.

| Page / feature | Status | Severity | Evidence / remaining work | Screenshots / score |
|---|---|---|---|---|
| Home: banner, navigation, menus | differs | P1 | Navigation change removes auth-driven crowding, preserves single-line CTA, adds disclosure state/Escape; screenshot verification pending | N/M |
| Home: hero layout, type, colors, spacing | differs | P1 | `site.css`: manually tuned layout; current original measurement required | N/M |
| Home: hero art and animation | differs | P2 | Original SVG lettering and CSS wave bars; E1 | N/M |
| Home: logo strip | differs | P2 | App-name compatibility strip replaces customer marks; E2 | N/M |
| Home: speed comparison and scroll demos | differs | P1 | Four sticky stages, fixed heights; compare every stage at both widths | N/M |
| Home: feature grid and style preview | differs | P2 | Three tiles; tab semantics and keyboard behavior incomplete | N/M |
| Home: privacy/security card | differs | P2 | Local-device claims replace external certifications; E3 | N/M |
| Home: testimonials | differs | P1 | Unattributed first-person quote and generic testimonial-like statements; replace with factual product information | N/M |
| Home: FAQ, CTA and download | differs | P1 | Limited FAQ, source-build fallback; minimum OS copy inconsistent with README (14 vs 14.2) | N/M |
| Home: mobile layout | differs | P1 | Multiple overrides and fixed heights; overflow, order and tap targets unverified | N/M |
| Home/pricing: footer and links | missing | P1 | Most original destinations absent; complete inventory below | N/M |
| Cookie/privacy controls | differs | P2 | Footer says no tracking/cookie banner; verify scripts/storage before validating E4 | N/M |
| Pricing: cards and billing toggle | differs | P1 | `$0` clone and comparison labels; toggle only changes CSS selection; E5 | N/M |
| Pricing: compare table | differs | P1 | `pricing.html`: compare current rows, supported features, mobile scrolling | N/M |
| Pricing: ROI calculator | differs | P2 | Number inputs permit negative/nonfinite values; clamp and explain assumptions | N/M |
| Pricing: FAQ | differs | P2 | JS-created answers and selected-class controls lack complete accessible state | N/M |
| Pricing: security card and CTA | differs | P2 | Independent-project claims; preserve E3/E5 | N/M |
| Pricing: mobile card collapse | differs | P2 | Toggle exists; verify controls, expanded copy and heights | N/M |
| Login: visual layout | differs | P1 | `login.html` contains duplicate body start; mobile art/card needs capture | N/M |
| Login: Google sign-in/button | differs | P1 | Existing supplied official SVG; `site.css` overrides approved button styling; popup not tested | N/M |
| Login: Apple/Microsoft/SSO | missing | P1 | Buttons currently report unavailable; E6, configuration decision required | N/M |
| Email login/signup | differs | P1 | Email-first Firebase implementation, no request lock; signed-in redirect defaults to marketing | N/M |
| Password reset and verification | differs | P1 | Reset link exists; no verification-code flow, resend UX, or email edit step | N/M |
| Auth validation/error/loading | differs | P1 | SDK import/persistence failures are uncaught, config failure disables all controls, no retry | N/M |
| Account identity/loading | differs | P1 | Account recovery change adds loading, retry and 401-only redirect; five source-level tests pass; browser pending | N/M |
| Account sign-out | differs | P1 | Account recovery change checks DELETE success, blocks duplicates and retains failed state; live smoke blocked | N/M |
| Home/pricing account access | differs | P2 | Navigation change moves account access to footer/mobile menu; sign-out uses account page recovery flow | N/M |
| Browser dictation demo | differs | P0 | `/demo` uses Web Speech with typed fallback; live microphone/browser validation pending, E7/E9 | N/M |
| Idle/listening/transcribing/polishing/result | differs | P0 | State machine includes permission, cancellation, recovery and timeout states; unit-tested, browser pending | N/M |
| Filler removal/punctuation/formatting | differs | P0 | Conservative local English rules, spoken punctuation/paragraphs/bullets; E7 | N/M |
| Tone/style options | differs | P1 | Four deterministic English styles in demo; no model rewriting, E7 | N/M |
| Personal dictionary | missing | P1 | Native implementation only; browser CRUD/replacement absent | N/M |
| Snippets | missing | P1 | Native implementation only; browser CRUD/expansion absent | N/M |
| Command mode | missing | P1 | Native model implementation; browser free equivalent needed, E7 | N/M |
| History/copy/delete/recovery | missing | P1 | Native implementation only; browser storage/privacy design needed | N/M |
| Settings: hotkey/language/microphone | differs | P1 | Demo language selector and focused-page shortcut; customization/device settings pending, E8/E9 | N/M |
| Settings: privacy/storage | differs | P1 | Demo discloses browser speech service and keeps drafts in memory only; preferences pending | N/M |
| Browser onboarding | missing | P1 | Permission/practice/language/style onboarding absent | N/M |
| Microphone denied/unavailable/no speech | differs | P0 | Recoverable messages and timeouts tested with injected recognizer; real permissions/audio pending | N/M |
| Keyboard/focus/reduced motion | differs | P1 | Nav and tabs incomplete, no explicit reduced-motion treatment found | N/M |
| Branded 404 | missing | P2 | No 404 page or site-level route | N/M |

## Original navigation/footer inventory

Observed public destinations, deduplicated, as of the audit date. A hash link to a generic home section is **not** a matching destination. The original's responsive/hover-only nav and links inside every article remain to be inspected in a real browser. Clone routes are relative to `/wisprflowisdead`.

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

## Justified constraints and proposed exceptions

These document constraints, not a blanket waiver for unfinished work. Outstanding bugs/missing implementations above must not be changed to `match` based on these entries.

- **E1 — proprietary appearance assets:** preserve original project art, icons, disclaimer and OFL Figtree/EB Garamond. Recreate layout, not Wispr source/art/audio models. Measurements still required.
- **E2 — customer evidence:** do not reuse Wispr customers/marks, invent clone customers, or present made-up testimonials. Use factual product capabilities until independently attributable clone feedback exists.
- **E3 — certifications:** do not imply SOC 2, HIPAA, ISO certification or enterprise guarantees for this project. Describe actual implementation instead.
- **E4 — privacy UI:** do not add a nonfunctional consent banner for visual similarity. First verify cookies, SDK traffic and storage, then provide controls the clone actually needs.
- **E5 — pricing/payment:** preserve the existing free clone and all payment behavior. Original paid-plan labels may be comparative only; do not create checkout, trial, billing or fake enterprise services.
- **E6 — providers:** existing Firebase email/password and Google must work. Apple, Microsoft and SAML require provider/tenant configuration; no credentials/configuration changes are authorized in this task. Disabled/clear unavailable states are preferable to misleading buttons. Exact provider parity needs a maintainer decision.
- **E7 — transcription/polish:** Web Speech and deterministic cleanup are the implemented free browser alternative, not equivalent to Wispr models. Accuracy, correction semantics and unrestricted AI rewriting must be documented honestly. Browser recognition may use the browser vendor's server; never describe it as guaranteed local/offline.
- **E8 — operating-system integration:** browser shortcuts work while the page is focused, cannot reproduce global Fn hooks or insert into arbitrary desktop apps. Keep native app handoff available.
- **E9 — microphone/language support:** browser recognition support and device selection differ by engine. Detect capabilities, expose only working settings, and provide a typed practice fallback. Test real microphone permission and audio on a supported browser.
- **E10 — organization-only destinations:** merchandise, sales, hiring, affiliates and bounties cannot be fabricated. Proposed exception is a clear project information/support destination or omission, subject to maintainer review.

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

Draft PR: pending publication, stacked on #2.

- Before: browser account page offered a native download only. No browser transcription or cleanup flow existed.
- After: public `/demo` offers four writing contexts, editable/copyable output, language/style choices, and a speech state machine covering idle, permission request, listening, transcribing, polishing, result, cancellation, and recoverable error. The account page and marketing footers link to it.
- Web Speech is capability-checked and starts only on user interaction. Permission/network/device/language/no-speech errors, permission/stop timeouts, cancellation, page hiding, and late callbacks are handled. Partial text can be recovered into typed practice; it is never silently presented as a final transcript.
- Local English cleanup removes conservative fillers/repetitions and supports spoken punctuation, paragraph and bullet commands. URL/email/code literals remain intact. Four styles change capitalization/end punctuation only; they do not reproduce model rewriting. Other languages retain recognized text. E7–E9 apply.
- Drafts remain in page memory. No audio recording, transcript storage, service credentials, paid service, or new account requirement is introduced. The page discloses that browser speech services may send audio off device. Dictionary, snippets, history and persistent settings remain separate unfinished work.
- `npm run lint --prefix site` and `npm run build --prefix site`: passed. New dependency-free scripts parse JavaScript (including inline scripts) and check local asset paths. The site is deployed as source, with no bundler; these checks do not claim HTML/CSS visual or semantic validation.
- `npm test --prefix site`: **15 passed**, including the five account tests and ten speech/cleanup tests. Recognition events are injected, not real audio or browser permission tests.
- Shared live auth smoke was attempted before publication and failed at Chromium launch before navigation. No account was created. Screenshots and scores remain unavailable, **N/M → N/M**. This change stays a draft until live auth, browser, microphone and paired viewport checks pass.

## Next verification gates

1. Restore browser launch and network/dependency access. Install website and parity dependencies; supply environment through the existing deployment workflow, never a committed .env file.
2. Capture original/live baseline at 1440 × 900 and 390 × 844, plus menus, hover/focus, scroll and cookie states excluded by parity.mjs. Save computed styles alongside paired images.
3. Create dedicated email-only free test accounts where eligible, run signup → sign-out → login → sign-out, then delete those accounts. Do not use existing personal sessions, SSO on the original, trials or payment details.
4. Complete remaining logical PR areas, append measured before/after evidence for each, and rerun smoke per PR. No merge is authorized.
5. Home/pricing/login must each reach 90+ at both widths; all matrix items need a verified match or an explicitly justified exception. Current state does not satisfy this gate.
