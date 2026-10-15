# Hosted browser evidence

`Website parity` runs on GitHub's Ubuntu runner for website/QA pull requests. It checks the website, installs Chromium and the lockfile from a pinned `isdead-design` commit, then captures original, live clone and candidate pages at 1440×900 and 390×844. It requires no deployment credentials or configured repository secrets. Same-repository PRs additionally run the shared signup/sign-out/login/sign-out smoke against live auth, using one disposable account per frontend and deleting each afterward. The browser job has `contents: read`. A separate archive job has `contents: write` only to preserve public evidence on a new `qa/parity-evidence-<run>-<attempt>` branch; it never updates the PR branch or main.

The candidate is the PR's head commit, served by `qa/serve.mjs`. This server only exposes public site files and the live **public** config endpoint. Session GET always returns 401, and writes return 405. It is for anonymous layout checks, not a substitute for Vercel, authentication or the signup/logout/login/logout smoke test.

The uploaded `wispr-parity-<run-id>` artifact contains:

- `live/` and `candidate/`: shared `scripts/parity.mjs` scores and original/clone/diff/side-by-side PNGs. Valid original captures are reused for the candidate comparison.
- `styles/{original,live,candidate}/`: shared `scripts/extract-styles.mjs` output, including computed fonts, spacing, colors, radii, shadows and geometry.
- `raw/`: unmodified viewport screenshots, browser errors and navigation/footer link inventory. Unlike the shared parity captures, these do not suppress cookie banners or animations.
- `behavior/`: real Chromium checks for navigation, pricing controls, and typed demo/library/command/history/settings flows, with screenshots at both widths. These use fresh browser contexts, no accounts, and no real microphone. They are not an auth/audio pass.
- `auth/`: shared smoke2 results, server identity/cookie checks and masked account screenshots for live and candidate frontends. Passwords, tokens, cookie values and storage state are never written. Cleanup failure fails the gate and reports only the disposable email/UID needed for follow-up.
- `verification.json` and `SUMMARY.md`: commits, capture failures and score deltas. Live-versus-candidate measures the whole PR stack, not the isolated contribution of a single PR.

The job fails when any capture/browser-check stage fails, a page returns a non-200 status, or any candidate score is below 90/has horizontal overflow. A green result still requires visual inspection: neither HTTP success nor a coarse image score proves content, accessibility or auth parity. Full paired/diff artifacts are retained for 14 days. The archive branch keeps raw viewport screenshots, behavior screenshots, style JSON and reports under `docs/parity/<run>-<attempt>/` for longer review, without copying the large full-page diff images into git. No credentials or storage states are captured. Auth screenshots use only the test-created account and mask its identity text. Manual cancellation or runner loss can interrupt cleanup; a failed cleanup is never reported as a pass. Workflow concurrency lets active runs finish before queued replacements. Fork PRs do not run the archive job.

To run locally with an `isdead-design` checkout at `parity-tools/`:

```sh
npm ci --prefix parity-tools/scripts
parity-tools/scripts/node_modules/.bin/playwright install --with-deps chromium
node qa/serve.mjs
# In another terminal:
node qa/browser-behavior.mjs
node qa/capture-parity.mjs
```

`PARITY_TOOLS_DIR` can point to another checkout. These QA commands do not deploy or merge anything.

## Authentication verification

`node qa/auth-smoke.mjs live` executes the pinned `isdead-design/templates/smoke2.mjs`. `node qa/auth-smoke.mjs candidate` executes that same UI flow with PR HTML/assets served through Playwright routing on the live origin; API calls still reach the deployed Firebase/session backend. This checks the candidate frontend with the real backend without deploying, provisioning secrets, or changing API/payment code. It does not prove candidate Vercel routing or headers. The runner verifies the template fingerprint before installing its cleanup/session hooks.

Each flow checks the matching server identity and Secure/HttpOnly/SameSite cookie after signup/login, and requires server 401 plus no session cookie after each UI sign-out. Cleanup uses only the generated email/password or its captured Firebase token, verifies that account's email and UID, and deletes it with Firebase's documented account API. Cleanup runs after success or failure, with three attempts, before the browser closes. No personal session, SSO, paid trial, payment details or original-site account is used. The reserved example.com mailbox cannot receive verification/reset email, so these flows do not verify email delivery or links.

Run `PARITY_TOOLS_DIR=/path/to/isdead-design node qa/auth-smoke.mjs candidate --check` to verify the pinned template and generated module syntax without opening a browser or creating an account. The hosted auth steps run only for same-repository pull requests. Their reports are required by the score gate when `RUN_AUTH_SMOKE=true`.

Login raw captures preserve both initial and settled forms. Clone captures record SDK ready/error state; the original check records only a visible, editable email field, without claiming authentication readiness or submitting a form. Visible control metadata helps distinguish markup differences from setup failures. Shared login scoring now waits 26 seconds on both original and clone, exceeding the clone's 25-second setup timeout. This is a measurement-protocol change; earlier login scores may represent loading and are not directly comparable. `capture-config.json` records that configuration, and login's actual scored PNGs are archived alongside raw captures.

[Run 38794977597](https://github.com/tommy-muckstack/wisprflowisdead/actions/runs/38794977597) passed both auth smokes, including account deletion and session cleanup, and all six anonymous browser groups. Its visual gate still failed; see `docs/PARITY_REPORT.md` for scores and the original-form capture correction.

Cleanup reference: [Firebase Auth REST account deletion](https://firebase.google.com/docs/reference/rest/auth#section-delete-account).
