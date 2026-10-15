# Website parity evidence

Live production is compared with the entire PR stack, not attributed to this single PR. Candidate preview supports anonymous rendering only; no authentication pass is implied. Shared parity hides animation/cookie overlays; the raw directory captures unmodified viewports and navigation/footer links. Scores still require visual review of the captured pages.

HTTP-valid measurements: true. Browser flows passed: false. All verification gates passed: false.

| Page | Viewport | Live | Candidate | Change |
|---|---|---:|---:|---:|
| home | 1440x900 | 79.1 | 79 | -0.1 |
| home | 390x844 | 61.9 | 56.9 | -5.0 |
| pricing | 1440x900 | 75 | 57 | -18.0 |
| pricing | 390x844 | 75.1 | 59.3 | -15.8 |
| login | 1440x900 | 79 | 78.1 | -0.9 |
| login | 390x844 | 78.5 | 67.5 | -11.0 |

Capture errors: browser interactions
