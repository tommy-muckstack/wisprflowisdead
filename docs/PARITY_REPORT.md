# WisprFlowIsDead parity report

Audit date: 2026-10-15. Upstream baseline: `71e3e684ff333da4732ad92da5347d446e9feec7`.
Scope: marketing website, shared Firebase account flow, and a browser dictation experience. The native Swift app is a separate, existing implementation.

**Not complete. No visual parity score or live authentication pass has been established in this audit.**

## Evidence and environment

- Read the repository README, website README, existing product spec, upstream contributing guide, and shared parity/smoke scripts. No repository AGENTS.md or .env.example exists at the baseline.
- Git cloning failed with DNS errors even with escalation. Retrieved 78 files through the GitHub connector and verified each Git blob SHA against the pinned tree. Two native-only TTF files were not retrieved; all website files and fonts are present. The local import commit is not an upstream commit and must not be pushed as the PR base.
- `site/` is the Vercel project root; functions are in `site/api/`. Only home, pricing, login, and app HTML routes exist. There are no website lint/build/test scripts at baseline.
- Public text/navigation inspected on [home](https://wisprflow.ai), [pricing](https://wisprflow.ai/pricing), [get started](https://wisprflow.ai/get-started), and the [help center](https://docs.wisprflow.ai). This is source/text evidence, not a rendered-browser comparison. Responsive nav menus, hover states, and current computed styles remain unobserved.
- No reference captures at `/workspace/isdead-shots/parity/wisprflowisdead/`. The local in-app browser execution tool is unavailable. Standalone Playwright Chromium fails at launch with macOS `bootstrap_check_in ... MachPortRendezvousServer` permission errors, including escalated attempts.
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
| Home: banner, navigation, menus | differs | P1 | `index.html`: static banner, inline mobile toggle; no expanded state or Escape handling | N/M |
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
| Home/pricing sign-out | differs | P1 | Existing inline handlers reload without checking response status | N/M |
| Browser dictation demo | missing | P0 | `app.html` is a download/account handoff, no recognizer | N/M |
| Idle/listening/transcribing/polishing/result | missing | P0 | Native FlowBar has analogous states; browser state machine absent | N/M |
| Filler removal/punctuation/formatting | missing | P0 | Native FlowCore only; browser implementation absent | N/M |
| Tone/style options | missing | P1 | Marketing preview only; no browser product settings | N/M |
| Personal dictionary | missing | P1 | Native implementation only; browser CRUD/replacement absent | N/M |
| Snippets | missing | P1 | Native implementation only; browser CRUD/expansion absent | N/M |
| Command mode | missing | P1 | Native model implementation; browser free equivalent needed, E7 | N/M |
| History/copy/delete/recovery | missing | P1 | Native implementation only; browser storage/privacy design needed | N/M |
| Settings: hotkey/language/microphone | missing | P1 | No browser settings; E8/E9 constrain parity | N/M |
| Settings: privacy/storage | missing | P1 | No browser settings; recognition-provider disclosure needed | N/M |
| Browser onboarding | missing | P1 | Permission/practice/language/style onboarding absent | N/M |
| Microphone denied/unavailable/no speech | missing | P0 | No browser recorder or permission/error UX | N/M |
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
| `/demo` | missing | Browser demo absent |
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
- **E7 — transcription/polish:** Web Speech and deterministic cleanup are the planned free browser alternative, not equivalent to Wispr models. Accuracy, correction semantics and unrestricted AI rewriting must be documented honestly. Browser recognition may use the browser vendor's server; never describe it as guaranteed local/offline.
- **E8 — operating-system integration:** browser shortcuts work while the page is focused, cannot reproduce global Fn hooks or insert into arbitrary desktop apps. Keep native app handoff available.
- **E9 — microphone/language support:** browser recognition support and device selection differ by engine. Detect capabilities, expose only working settings, and provide a typed practice fallback. Test real microphone permission and audio on a supported browser.
- **E10 — organization-only destinations:** merchandise, sales, hiring, affiliates and bounties cannot be fabricated. Proposed exception is a clear project information/support destination or omission, subject to maintainer review.

## Changes and verification ledger

### Account recovery

- Before: initial account could be displayed despite `hidden` because `.box` sets `display:grid`; network failures were treated as logged-out; DELETE failures were swallowed and redirected home.
- After: explicit hidden styling; visible loading status; retry on request/parse/server failure; redirect to login only for 401; show sign-out failure; lock duplicate DELETE; revalidate restored pages.
- `node --test site/tests/account.test.cjs`: **5 passed**. Tests exercise actual client code with mocked DOM/HTTP responses. This is not Firebase/browser end-to-end verification.
- `node --check site/wisprflowisdead/assets/account.js`: passed.
- `npm run lint` / `npm run build`: unavailable; baseline package has neither script. These are not reported as passed.
- Shared live auth smoke: attempted, blocked at Chromium launch before signup. Account cleanup: not applicable, no account created.
- Screenshots and score change: **unavailable, N/M → N/M**. Draft status required until browser/auth evidence is attached.

## Next verification gates

1. Restore browser launch and network/dependency access. Install website and parity dependencies; supply environment through the existing deployment workflow, never a committed .env file.
2. Capture original/live baseline at 1440 × 900 and 390 × 844, plus menus, hover/focus, scroll and cookie states excluded by parity.mjs. Save computed styles alongside paired images.
3. Create dedicated email-only free test accounts where eligible, run signup → sign-out → login → sign-out, then delete those accounts. Do not use existing personal sessions, SSO on the original, trials or payment details.
4. Complete remaining logical PR areas, append measured before/after evidence for each, and rerun smoke per PR. No merge is authorized.
5. Home/pricing/login must each reach 90+ at both widths; all matrix items need a verified match or an explicitly justified exception. Current state does not satisfy this gate.
