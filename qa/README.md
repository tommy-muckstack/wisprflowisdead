# Hosted browser evidence

`Website parity` runs on GitHub's Ubuntu runner for website/QA pull requests. It checks the website, installs Chromium and the lockfile from a pinned `isdead-design` commit, then captures original, live clone and candidate pages at 1440×900 and 390×844. It requires no deployment credentials or repository secrets. Workflow permissions are `contents: read`.

The candidate is the PR's head commit, served by `qa/serve.mjs`. This server only exposes public site files and the live **public** config endpoint. Session GET always returns 401, and writes return 405. It is for anonymous layout checks, not a substitute for Vercel, authentication or the signup/logout/login/logout smoke test.

The uploaded `wispr-parity-<run-id>` artifact contains:

- `live/` and `candidate/`: shared `scripts/parity.mjs` scores and original/clone/diff/side-by-side PNGs. Valid original captures are reused for the candidate comparison.
- `styles/{original,live,candidate}/`: shared `scripts/extract-styles.mjs` output, including computed fonts, spacing, colors, radii, shadows and geometry.
- `raw/`: unmodified viewport screenshots, browser errors and navigation/footer link inventory. Unlike the shared parity captures, these do not suppress cookie banners or animations.
- `verification.json` and `SUMMARY.md`: commits, capture failures and score deltas. Live-versus-candidate measures the whole PR stack, not the isolated contribution of a single PR.

The job fails when any capture stage fails, a page returns a non-200 status, or any candidate score is below 90/has horizontal overflow. A green result still requires visual inspection: neither HTTP success nor a coarse image score proves content, interactions, accessibility or auth parity. Artifacts are retained for 14 days; save reviewed evidence under `docs/` when updating the parity report. No credentials, storage states or authenticated screenshots are captured.

To run locally with an `isdead-design` checkout at `parity-tools/`:

```sh
npm ci --prefix parity-tools/scripts
parity-tools/scripts/node_modules/.bin/playwright install --with-deps chromium
node qa/serve.mjs
# In another terminal:
node qa/capture-parity.mjs
```

`PARITY_TOOLS_DIR` can point to another checkout. These QA commands do not deploy or merge anything.
