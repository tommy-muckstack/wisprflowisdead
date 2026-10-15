# Display italic font

The generated design stylesheet supplies only the normal EB Garamond face. Marketing headings use `<em>`, which previously synthesized an oblique shape from that face. `site.css` now declares the matching italic face separately so design-token synchronization does not remove it.

- File: `site/wisprflowisdead/assets/fonts/EBGaramond-Italic-Variable.woff2`
- Source: [Fontsource's EB Garamond Latin variable italic](https://github.com/fontsource/font-files/blob/main/fonts/variable/eb-garamond/files/eb-garamond-latin-wght-italic.woff2), retrieved 2026-10-15.
- Source Git blob SHA: `e3f81503a84c222684ee637cff7cfe2e45b421f4`, verified against the downloaded bytes.
- Size: 47,940 bytes. Weight axis: 400–800. Latin Unicode ranges follow the source CSS.
- License: SIL OFL 1.1, already included in `site/wisprflowisdead/assets/fonts/OFL-EBGaramond.txt`; its contents match the source license exactly (Git blob `da3ca89595df81b16855b86a4d0d370f34a908fa`). No original-site font file is copied.

The WOFF2 file is unmodified and served locally with `font-display: swap`. This fixes the missing face; visual scores and line wrapping must still be checked against the original, which may use a different font revision.
