# Analytics (PostHog)

One PostHog project (US cloud, project **666931**) collects the hub and every IsDead sub-app. The contract is the hub's
`yourappisdead/ANALYTICS.md`; this file is how the WisprFlowIsDead **website** (`site/`) follows it.

The native Mac app (`Sources/`) has no analytics and sends nothing.

## Setup
- `site/wisprflowisdead/assets/analytics.js` is a plain script loaded in the `<head>` of every page (the site has no bundler).
  It inlines the project's publishable token, so no environment variables are involved.
- Requests go through this site's own origin: `site/vercel.json` rewrites `/wisprflowisdead/ingest/static/*` to
  `us-assets.i.posthog.com` (which serves posthog-js `array.js`) and `/wisprflowisdead/ingest/*` to `us.i.posthog.com`.
- `$pageview` is captured once per page load. Autocapture, session replay, heatmaps and performance capture are off.
- Analytics is off when the browser sends Do Not Track, and on `localhost` / `127.0.0.1` unless
  `localStorage.isdead_ph_debug = "1"` (verbose logs, and automated browsers are accepted, for local verification only).
  posthog-js drops headless/automated browsers in production, so QA runs produce no captures.
- Every other script calls `globalThis.isdeadAnalytics.{track, trackNow, identify, reset}`. They are no-ops when analytics is off.

## Super properties (registered on every event)
| property | value | meaning |
| --- | --- | --- |
| `product` | `wisprflowisdead` | the one property to filter by (the hub sends `yourappisdead`) |
| `surface` | `landing` \| `app` | `app` = the browser demo (`/demo`) and the account page (`/app`); `landing` = everything else (home, pricing, support, login, 404) |
| `platform` | `web` | |
| `env` | `production` \| `development` | |

All IsDead apps share the yourappisdead.com cookie, so at boot the script unregisters other apps' leftover keys
(`app`, `app_family`, `base_path`, `suite_id`, `app_id`, `schema_version`, `source`, `site_id`, `environment`,
`account_type`) and then registers its own. `reset()` (sign-out) re-registers them.

## Identity
Signed-in users are identified by Firebase uid (shared across the family): at sign-in on the login page, and on the
account page from the session response (`GET /wisprflowisdead/api/session` now also returns `uid`). Visitors who are not
signed in are never identified.

## Events
Properties are kinds, counts and enums only. Dictated or typed text, emails, URLs and library entries are never sent.

| event | properties | fires from |
| --- | --- | --- |
| `landing_download_clicked` | `target` (`download_section`, `dmg`, `source_build`), `location` (`banner`, `nav`, `hero`, `footer`, `download_section`, `page`) | any download link on a landing page (`analytics.js`) |
| `landing_cta_clicked` | `target` (`login`, `demo`, `pricing`, `support`, `github`), `location` | landing-page links (`analytics.js`) |
| `app_signed_up` | `method` (`password`, `google`) | `login.mjs` via `AuthFlow.onSignedIn`, sent before the redirect |
| `app_signed_in` | `method` (`password`, `google`) | same |
| `app_signed_out` | | `account.js`, sent before the redirect |
| `app_dictation_started` | `context` (`prompt`, `message`, `list`, `email`), `command` (bool) | `demo.mjs`, microphone recording started |
| `app_dictation_completed` | `input` (`voice`, `typed`), `context`, `words` (count), `language`, `style`, `cleanup` | `demo.mjs`, result written to the editor |
| `app_command_applied` | `input` (`voice`, `typed`), `context` | `demo.mjs`, command mode result applied |
| `app_text_copied` | `context`, `words` (count) | `demo.mjs`, Copy succeeded |
| `app_history_restored` | `context` | `demo.mjs` |
| `app_library_entry_saved` | `kind` (`dictionary`, `snippet`), `edited` (bool) | `library-ui.mjs` |

Adding an event: call `isdeadAnalytics.track('app_<object>_<action>', {...})`, add a row here, and add it to the hub's
`yourappisdead/ANALYTICS.md`. Never put the product name in an event name.

## Verifying locally
Serve `site/` with an `/wisprflowisdead/ingest/static/*` proxy, set `localStorage.isdead_ph_debug = "1"`, and record events
with a `before_send` hook that returns `null` so nothing reaches PostHog (the hub kit's `ph-check.mjs` does this).
