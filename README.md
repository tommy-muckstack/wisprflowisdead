# WisprFlowIsDead

Free, open-source voice dictation for the Mac. Hold a key, talk, let go, and clean, punctuated text lands wherever your cursor is. Everything runs on your Mac: no account, no word limits, no subscription, nothing uploaded.

Part of the IsDead series at [yourappisdead.com](https://yourappisdead.com).

> WisprFlowIsDead is an independent project. It is not affiliated with, endorsed by, or connected to Wispr or Wispr Flow. "Wispr Flow" is a trademark of its owner and is used here only to describe what this app is an alternative to. No Wispr code, logos, icons, art or fonts are used.

## What it does

- **Push to talk**: hold `fn` (or `⌃⌥` on keyboards without fn), talk, release.
- **Hands-free**: `fn` + `space`, or double-tap `fn`. Press again to stop. A quick third tap cancels.
- **Flow Bar**: a small floating pill that shows live audio while you talk. Click it to start, drag it to the bottom, left or right edge, right-click to hide it for an hour.
- **Cleanup**: drops filler words and stutters, punctuates, formats numbers, emails and lists. Say "scratch that" or "no wait" to correct yourself.
- **Styles** per app type (personal messages, work messages, email, other): Formal, Casual, very casual, Excited.
- **Auto Cleanup** levels: None, Light, Medium, High. Medium and High use Apple's on-device model on macOS 26.
- **Dictionary**: names and jargon spelled your way, with "often heard as" fixes and stars.
- **Snippets**: say a cue like "my calendar link" and get the full text.
- **Command Mode** (experimental): hold `fn` + `⌃` and say what to do with the selected text. Uses Apple's on-device model (macOS 26).
- **History** with "Undo AI edit", **Insights** (words, words per minute, streak, top apps).
- Paste last transcript `⌘⌃V`, copy last `⌘⌃C`, all shortcuts rebindable (up to 4 per action, extra mouse buttons too).

## Requirements

macOS 14.2 or later. Speech recognition runs on device through [FluidAudio](https://github.com/FluidInference/FluidAudio) (Parakeet, about 600 MB, downloaded once) or Apple's built-in recognizer on macOS 26.

## Build and run

```sh
scripts/run-dev.sh        # builds, wraps in an .app, ad-hoc signs, opens
swift test                # FlowCore unit tests (also run on Linux)
```

Grant Microphone and Accessibility when asked. Accessibility lets the app type into other apps; without it, text goes to your clipboard.

The Mac app includes Sparkle automatic updates and a **Check for Updates…** menu item. Installer packaging, signing, verification and publication are documented in [docs/RELEASING.md](docs/RELEASING.md). Developer ID signing/notarization is separate from Sparkle's update signatures; the initial local installer is ad-hoc signed.

## Layout

| Path | What |
|---|---|
| `Sources/FlowCore` | Pure logic: shortcuts, hotkey state machine, styles, backtrack, lists, snippets, dictionary, history, insights, settings store. Includes MyMan's text cleanup (vendored). |
| `Sources/FlowVoice` | Microphone, speech-to-text and text insertion, vendored from [MyMan](https://github.com/tommy-muckstack/myman), behind a small public `VoiceEngine` API. |
| `Sources/WisprFlowIsDead` | The SwiftUI/AppKit app: Flow Bar, hub, settings, onboarding. |
| `docs/WISPRFLOW_SPEC.md` | The feature spec this is built against. |
| `docs/STATUS.md` | What's built and what's next. |

## License

Apache-2.0. See `LICENSE` and `NOTICE`. Figtree and EB Garamond are under the SIL Open Font License (`Sources/WisprFlowIsDead/Resources/Fonts/OFL-*.txt`). Theme tokens come from the shared IsDead design system (`scripts/sync-design.sh`).

## Website

The one-page site and `/login` live in [`site/`](site/README.md), deployed as its own Vercel project and served at yourappisdead.com/wisprflowisdead.

## Open source & contributing

This project is part of **[yourappisdead](https://yourappisdead.com)**, a marketplace of free, open-source clones of paid SaaS apps. It is an independent clone built from public product behavior; it is not affiliated with, endorsed by, or using any code or assets from the original product. All brand names belong to their owners.

- Licensed under Apache-2.0 (see `LICENSE`).
- Contributions are welcome: read the [contributing guide](https://github.com/tommy-muckstack/yourappisdead/blob/main/CONTRIBUTING.md) and the [code of conduct](https://github.com/tommy-muckstack/yourappisdead/blob/main/CODE_OF_CONDUCT.md), then open an issue or pull request.
- Want a different app killed? [Submit it on yourappisdead](https://yourappisdead.com/#submit).
- Please never commit secrets, keys or copied third-party assets (logos, screenshots, fonts without an open license).
- Shared design tokens, fonts and login live in [`isdead-design`](https://github.com/tommy-muckstack/isdead-design).

The website and app use the project owner’s tombstone/X identity. See [branding assets and generation notes](docs/BRANDING.md) for the palette and regeneration steps.
