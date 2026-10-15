# Website parity evidence

Live production is compared with the entire PR stack, not attributed to this single PR. Candidate layout preview is anonymous; separate auth reports exercise the deployed API with live/candidate frontend files. Login scoring now waits 26 seconds on both sites, so earlier loading-state scores are not directly comparable. Shared parity hides animation/cookie overlays; raw captures preserve initial and settled login states. Scores still require visual review.

HTTP-valid measurements: true. Browser flows passed: true. Auth smoke required/passed: true/true. All verification gates passed: false.

| Page | Viewport | Live | Candidate | Change |
|---|---|---:|---:|---:|
| home | 1440x900 | 79.1 | 80.2 | 1.1 |
| home | 390x844 | 61.9 | 66.2 | 4.3 |
| pricing | 1440x900 | 75 | 68.5 | -6.5 |
| pricing | 390x844 | 75.1 | 59.3 | -15.8 |
| login | 1440x900 | 79 | 93.6 | 14.6 |
| login | 390x844 | 78.5 | 91.9 | 13.4 |
