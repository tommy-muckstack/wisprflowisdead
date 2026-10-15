# Website parity evidence

Live production is compared with the entire PR stack, not attributed to this single PR. Candidate layout preview is anonymous; separate auth reports exercise the deployed API with live/candidate frontend files. Login scoring now waits 26 seconds on both sites, so earlier loading-state scores are not directly comparable. Shared parity hides animation/cookie overlays; raw captures preserve initial and settled login states. Scores still require visual review.

HTTP-valid measurements: true. Browser flows passed: false. Auth smoke required/passed: true/true. All verification gates passed: false.

| Page | Viewport | Live | Candidate | Change |
|---|---|---:|---:|---:|
| home | 1440x900 | 79.2 | 84.1 | 4.9 |
| home | 390x844 | 61.9 | 71.1 | 9.2 |
| pricing | 1440x900 | 75 | 74.7 | -0.3 |
| pricing | 390x844 | 75.1 | 73.7 | -1.4 |
| login | 1440x900 | 79 | 93.6 | 14.6 |
| login | 390x844 | 78.5 | 91.9 | 13.4 |
| support | 1440x900 | N/M (missing route) | 71.1 | N/M |
| support | 390x844 | N/M (missing route) | 64.9 | N/M |

Capture errors: browser interactions
