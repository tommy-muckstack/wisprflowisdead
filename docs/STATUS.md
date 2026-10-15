# Status

## Milestones

| # | Milestone | State |
|---|---|---|
| M0 | Spec (`docs/WISPRFLOW_SPEC.md`) from public sources | Done |
| M1 | FlowCore logic + 32 unit tests (Linux and macOS) | Done |
| M2 | Voice: vendored MyMan mic capture, on-device ASR (Parakeet / Qwen3 / Apple), typing into apps | Done, builds; not yet exercised by a person |
| M3 | Flow Bar: resting / hover / recording / hands-free / processing / command states, notices, drag-to-dock, hide for 1 hour | Done, builds; visuals unverified on screen |
| M4 | Hotkeys: push to talk, double-tap and Fn+Space hands-free, cancel, paste/copy last, press Enter, command mode, mouse buttons | Done, builds |
| M5 | Hub: Home history (Undo AI edit), Insights, Dictionary, Snippets, Style + Auto Cleanup, Settings, shortcut editor, Help | Done, builds |
| M6 | Onboarding: welcome, permissions, mic test, fn key detection by question, practice, styles | Done, builds |
| M7 | Command Mode via Apple Foundation Models (macOS 26) and web search | Done, builds |

Verified: `swift build`, `swift test` (32/32) and the `.app` assembly script pass on macOS 27 / Xcode 26.4. FlowCore tests also pass on Linux (Swift 6.1). The app has not been launched and clicked through yet.

## Not built yet (parity gaps)

- Esc does not get swallowed during dictation (the event tap is listen-only); Fn's system action (emoji picker) is not suppressed.
- Clipboard-paste insertion with restore; we type keystrokes instead (MyMan's approach). Rich-text snippets paste as plain text.
- Microphone picker, ranking, hot-swap, clamshell warning; uses the system default input.
- Saved audio, playback, Retry and Recover for failed or quit-mid-dictation takes.
- Auto-add to dictionary when you fix a pasted word (logic exists in FlowCore, no editor watching).
- Context awareness (reading on-screen names), developer file tagging, multi-language picker in the bar.
- Transforms, Scratchpad, Notetaker, sync, teams.
- Session cap is checked once a minute (warns in the 19th minute, stops at 20).
- App icon (original art needed), screenshots for the README.
