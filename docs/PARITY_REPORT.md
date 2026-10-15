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
- Cached Playwright Firefox and WebKit were also attempted against the local server with escalation. Both abort before navigation (`SIGABRT` / `Abort trap: 6`). The local HTTP server responds, but no installed engine has produced a website screenshot.
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
| Website/native branding and icons | differs | P2 | User-requested tombstone replaces the waveform identity; intentional exception E11, assets inspected, rendered verification pending | N/M |
| Home: banner, navigation, menus | differs | P1 | Navigation change removes auth-driven crowding, preserves single-line CTA, adds disclosure state/Escape; screenshot verification pending | N/M |
| Home: hero layout, type, colors, spacing | differs | P1 | `site.css`: manually tuned layout; current original measurement required | N/M |
| Home: hero art and animation | differs | P2 | Original SVG lettering and CSS wave bars; E1 | N/M |
| Home: logo strip | differs | P2 | App-name compatibility strip replaces customer marks; E2 | N/M |
| Home: speed comparison and scroll demos | differs | P1 | Unsupported speed claims removed; linear fallback for reduced motion, small viewports and no JS; desktop scroll stages still need rendered comparison | N/M |
| Home: feature grid and style preview | differs | P2 | Linked tab/panel semantics, arrow/Home/End navigation and focus styling implemented; browser verification pending | N/M |
| Home: privacy/security card | differs | P2 | Mac-local processing distinguished from browser service; no external certification claims, E3 | N/M |
| Home: testimonials | differs | P2 | Anonymous quotes replaced with factual product cards; intentional E2, layout comparison pending | N/M |
| Home: FAQ, CTA and download | differs | P1 | Minimum OS corrected to 14.2; limited FAQ and source-build fallback remain | N/M |
| Home: mobile layout | differs | P1 | Multiple overrides and fixed heights; overflow, order and tap targets unverified | N/M |
| Home/pricing: footer and links | missing | P1 | Most original destinations absent; complete inventory below | N/M |
| Cookie/privacy controls | differs | P2 | Footer says no tracking/cookie banner; verify scripts/storage before validating E4 | N/M |
| Pricing: cards and billing toggle | differs | P1 | Explicit original-plan comparison with working period/add-on reference rates; clone remains free, E5; rendered comparison pending | N/M |
| Pricing: compare table | differs | P1 | Five-column table roles, included/not-included labels, all four plans reachable in mobile scroll region; current original geometry unverified | N/M |
| Pricing: ROI calculator | differs | P2 | Bounded finite inputs, visible errors, disclosed hypothetical assumptions and fractional calculation; browser checks pending | N/M |
| Pricing: FAQ | differs | P2 | Static answers, desktop keyboard tabs and mobile accordion state; every question reachable, rendered checks pending | N/M |
| Pricing: security card and CTA | differs | P2 | Mac/browser processing distinction and explicit absence of certifications; source/support destinations preserve E3/E5 | N/M |
| Pricing: mobile card collapse | differs | P2 | Linked controls and expanded copy, breakpoint updates, no-JS content fallback; sizing/focus checks pending | N/M |
| Login: visual layout | differs | P1 | Duplicate body removed; responsive card/focus fixes and provider styling drafted; capture pending | N/M |
| Login: Google sign-in/button | differs | P1 | Existing official gradient G retained; approved white/gray/Google Sans treatment restored; popup/rendering untested | N/M |
| Login: Apple/Microsoft/SSO | missing | P1 | Unavailable providers are disabled with visible explanation; E6, configuration decision required | N/M |
| Email login/signup | differs | P1 | Locked email-first flow with editable email and recoverable signup continuation; default return is account page | N/M |
| Password reset and verification | differs | P1 | Reset view and verification-link resend added; Firebase link verification differs from original email-code flow, E6 | N/M |
| Auth validation/error/loading | differs | P1 | Config/SDK setup timeout and retry, operation status, native validation, friendly errors; live SDK checks pending | N/M |
| Account identity/loading | differs | P1 | Account recovery change adds loading, retry and 401-only redirect; five source-level tests pass; browser pending | N/M |
| Account sign-out | differs | P1 | Account recovery change checks DELETE success, blocks duplicates and retains failed state; live smoke blocked | N/M |
| Home/pricing account access | differs | P2 | Navigation change moves account access to footer/mobile menu; sign-out uses account page recovery flow | N/M |
| Browser dictation demo | differs | P0 | `/demo` uses Web Speech with typed fallback; live microphone/browser validation pending, E7/E9 | N/M |
| Idle/listening/transcribing/polishing/result | differs | P0 | State machine includes permission, cancellation, recovery and timeout states; unit-tested, browser pending | N/M |
| Filler removal/punctuation/formatting | differs | P0 | Conservative local English rules, spoken punctuation/paragraphs/bullets; E7 | N/M |
| Tone/style options | differs | P1 | Four deterministic English styles in demo; no model rewriting, E7 | N/M |
| Personal dictionary | differs | P1 | Browser word/correction CRUD, search/sort/star and literal replacement implemented; recognition bias/learning and visual checks pending | N/M |
| Snippets | differs | P1 | Browser CRUD and case-preserving plain-text expansion implemented; rich text/import/sync and rendered checks pending | N/M |
| Command mode | missing | P1 | Native model implementation; browser free equivalent needed, E7 | N/M |
| History/copy/delete/recovery | differs | P1 | Browser text history, original/result restore, search/copy/delete, retention and storage recovery drafted; audio replay/retry unavailable, live checks pending | N/M |
| Settings: hotkey/language/microphone | differs | P1 | Demo language selector and focused-page shortcut; customization/device settings pending, E8/E9 | N/M |
| Settings: privacy/storage | differs | P1 | Library saving is opt-in; history offers page-only, 24-hour, until-deleted and disabled modes; browser/account isolation and real retention checks pending | N/M |
| Browser onboarding | missing | P1 | Permission/practice/language/style onboarding absent | N/M |
| Microphone denied/unavailable/no speech | differs | P0 | Recoverable messages and timeouts tested with injected recognizer; real permissions/audio pending | N/M |
| Keyboard/focus/reduced motion | differs | P1 | Nav/demo tab keyboard and focus behavior drafted; demo/auth reduced-motion rules exist; sitewide manual accessibility verification pending | N/M |
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

Draft branch: `qa/browser-history`, stacked on #8.

- Before: completed browser dictations and typed practice had no history list or recovery after changing drafts.
- After: Recent activity stores each completed result once, with original words, language/style/context and timestamp. It offers search, copy, full-text inspection, restore-result/restore-original with overwrite confirmation, individual deletion and clear-all. Restoring is disabled during recording/cleanup. Text is rendered literally; no user content is inserted as HTML.
- Default history exists only in page memory. Explicit choices save text for 24 hours or until deleted, or remember a disabled-history preference with no transcripts. Changing to page-only removes the saved copy. The feature owns only `wisprflowisdead.history.v1`; dictionary/snippet data and unrelated applications are untouched. No audio is recorded or retained by this feature.
- Expiry is enforced on load, once per minute while open, and on foreground/page restoration. A browser page cannot delete storage while closed; the UI discloses this. Expired entries stay hidden when physical removal fails, and deletion is retried. Failed writes/deletes do not report success; the current result stays in the editor, and the latest failed history save can be retried. Known cross-tab changes prevent stale writes and refresh the visible saved history. Unreadable saved data is preserved until explicitly cleared.
- Bounds: 200 entries, 200,000 characters each for result/original, and a 4,000,000-character saved payload. Reaching a bound shows an error instead of silently dropping earlier results. Browser storage can impose a smaller limit. Preferences requiring storage cannot be saved when the browser blocks it; page-only history remains available.
- Remaining differences: this public demo's history belongs to a browser profile, not an authenticated account; signing out does not clear it, and the UI states how to clear it. Original account-linked cleanup/sync needs a separate decision/implementation. Audio playback and recognition retry from retained audio are unavailable because Web Speech does not supply a retained recording (E7/E9). Original default storage and precise native Hub layout are not matched.
- Website lint/build, whitespace and source integration checks pass. **49 tests pass**, including ten history validation/storage/expiry/conflict tests. These validate deterministic logic, not actual browser persistence, privacy permissions, microphone capture or native history parity.
- Shared live smoke2 with cleanup was attempted and failed at Chromium launch before navigation; no account was created. Website screenshots, computed styles and parity remain **N/M → N/M**. The change remains a draft pending browser, live auth and microphone verification.
- References: [original history deletion and retention](https://docs.wisprflow.ai/articles/4465314211-delete-transcripts-and-history-in-wispr-flow), [original data-sharing/local-history controls](https://docs.wisprflow.ai/articles/9609615338-private-cloud-sync-and-data-sharing-preferences-in-wispr-flow).

## Next verification gates

1. Restore browser launch and network/dependency access. Install website and parity dependencies; supply environment through the existing deployment workflow, never a committed .env file.
2. Capture original/live baseline at 1440 × 900 and 390 × 844, plus menus, hover/focus, scroll and cookie states excluded by parity.mjs. Save computed styles alongside paired images.
3. Create dedicated email-only free test accounts where eligible, run signup → sign-out → login → sign-out, then delete those accounts. Do not use existing personal sessions, SSO on the original, trials or payment details.
4. Complete remaining logical PR areas, append measured before/after evidence for each, and rerun smoke per PR. No merge is authorized.
5. Home/pricing/login must each reach 90+ at both widths; all matrix items need a verified match or an explicitly justified exception. Current state does not satisfy this gate.
