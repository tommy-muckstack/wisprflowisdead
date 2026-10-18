# Website parity evidence

Live production is compared with the entire PR stack, not attributed to this single PR. Candidate layout preview is anonymous; separate auth reports exercise the deployed API with live/candidate frontend files. Login scoring now waits 26 seconds on both sites, so earlier loading-state scores are not directly comparable. Shared parity hides animation/cookie overlays; raw captures preserve initial and settled login states. Scores still require visual review.

HTTP-valid measurements: true. Browser flows passed: true. Auth smoke required/passed: true/true. All verification gates passed: false.

| Page | Viewport | Live | Candidate | Change |
|---|---|---:|---:|---:|
| home | 1440x900 | 84.5 | 84.5 | 0.0 |
| home | 390x844 | 71.1 | 71.1 | 0.0 |
| pricing | 1440x900 | 75.7 | 75.7 | 0.0 |
| pricing | 390x844 | 77 | 77 | 0.0 |
| login | 1440x900 | 71.4 | 71.4 | 0.0 |
| login | 390x844 | 79.3 | 79.3 | 0.0 |
| support | 1440x900 | N/M (missing route) | 71.1 | N/M |
| support | 390x844 | N/M (missing route) | 65.9 | N/M |
