# Website parity evidence

Live production is compared with the entire PR stack, not attributed to this single PR. Candidate layout preview is anonymous; separate auth reports exercise the deployed API with live/candidate frontend files. Login scoring now waits 26 seconds on both sites, so earlier loading-state scores are not directly comparable. Shared parity hides animation/cookie overlays; raw captures preserve initial and settled login states. Scores still require visual review.

HTTP-valid measurements: true. Browser flows passed: true. Auth smoke required/passed: true/true. All verification gates passed: false.

| Page | Viewport | Live | Candidate | Change |
|---|---|---:|---:|---:|
| home | 1440x900 | 79.2 | 79 | -0.2 |
| home | 390x844 | 61.9 | 56.9 | -5.0 |
| pricing | 1440x900 | 75 | 67.9 | -7.1 |
| pricing | 390x844 | 75.1 | 59.5 | -15.6 |
| login | 1440x900 | 79 | 78.1 | -0.9 |
| login | 390x844 | 78.5 | 67.5 | -11.0 |

Capture errors: raw viewport captures
