# Wispr Flow: product spec for WisprFlowIsDead

Source basis: Wispr Flow public site (features, pricing, changelog through 2026-10-09) and help center articles, read 2026-10-14. No live install was torn down, so pixel sizes and animation timings marked *(est.)* are estimates to verify against the real app. WisprFlowIsDead copies behavior and layout, never Wispr's logos, icons, illustrations, copy or fonts.

Scope for v1 of the clone: **macOS desktop dictation**. Notetaker (meetings), Scratchpad, Teams/Enterprise admin, mobile keyboards and cloud sync are listed for completeness and marked out of scope.

## 1. Core loop

1. User focuses any text field in any app.
2. Holds **Push to talk** (default `Fn`). The Flow Bar expands into the recording state and shows live audio bars.
3. Releases. Bar switches to processing. Audio is transcribed, cleaned by AI, then inserted at the cursor of the field focused *at release time*.
4. Clipboard is used briefly for insertion and the previous clipboard is restored ~0.5 s after the target reads it. If insertion fails, the transcript stays on the clipboard and a failure toast offers **Copy**.

Rules:
- A Push-to-talk tap released in < 0.5 s does not paste; Flow waits briefly for a second press (double-tap = hands-free), otherwise cancels and shows a "hold the shortcut" tip.
- **Hands-free**: press `Fn+Space`, or double-press Push to talk within 0.5 s. Press again to stop and insert. A third quick press after a double-press cancels.
- **Click the Flow Bar** to start (keeps focus in target field); click again to stop; clicking within 0.5 s of starting cancels.
- **Cancel**: `Esc` (rebindable, one binding only). Escape does not reach other apps during dictation. Hands-free shows an X button.
- Session cap: warn at 19 min, stop at 20 min ("Flow supports up to 20 minutes per session", **Recover text**).
- Silence / muted mic: nothing is sent; warn "Is your microphone muted?". Since Oct 2026 also warn immediately at start if mic registers no sound.
- New dictation while the previous one processes is ignored with "Flow was processing your last transcript".
- Quitting mid-dictation saves audio; History offers **Recover**.

## 2. Shortcuts (Settings → General → Shortcuts → Change)

| Action | Mac default | No-Fn-key Mac fallback | Windows |
|---|---|---|---|
| Push to talk (hold) | Fn | Ctrl+Opt | Ctrl+Win |
| Hands-free (toggle) | Fn+Space | Ctrl+Opt+Space | Ctrl+Win+Space |
| Command Mode (hold) | Fn+Ctrl | Cmd+Ctrl+Opt | Ctrl+Win+Alt |
| Paste last transcript | Cmd+Ctrl+V | same | Shift+Alt+Z |
| Copy last transcript | Cmd+Ctrl+C | same | Shift+Alt+X |
| Cancel | Esc | same | Esc |
| Press Enter | unbound | | |
| Open Scratchpad | Opt+S | | |

Recorder rules: up to 4 bindings per action (Cancel: 1); max 3 keys; must include a modifier (Ctrl, Cmd, Opt, Shift, Fn) or valid mouse button (Middle, Mouse 4-10); no left+right of same modifier; no duplicates across actions; blocked: Cmd+Backspace, Cmd+Delete, Cmd+Space, Cmd+Ctrl+F, Cmd+C, Cmd+V, standalone letters/numbers/punctuation. Standalone exceptions: Caps Lock (PTT / hands-free only), Escape (Cancel only). Keyboard combos save on release, mouse on press. Errors: "This shortcut is not allowed: {key}", "This shortcut is already in use", "Shortcut must contain 3 or fewer keys", "Shortcut must include a modifier key or a valid mouse button", "Shortcut cannot contain both left and right version of the same key". Overlap warning when hands-free is contained in PTT. Trash icon removes a binding; PTT, Command, Paste last, Copy last and Cancel must keep one. **Reset to default** (no undo). **Done** button closes. Live hint "Double-tap {PTT} for hands-free". Shortcuts are per device.

## 3. Flow Bar (floating pill)

States:
1. **Hidden** until onboarding finishes; then **Resting**: a tiny dark pill at bottom-center above the Dock *(est. 36x8 pt, 50% opacity)*.
2. **Hover (resting)**: grows *(est. 160x28)* and shows hint "Click or hold Fn to start dictating"; reveals language picker (if >1 language), mic switcher, optional Scratchpad button, Transforms wand when text is selected.
3. **Recording (hold)**: black pill *(est. 112x32)* with ~9-15 white vertical bars whose heights follow mic RMS at ~30 fps, smooth spring.
4. **Recording (hands-free)**: same plus **X** (cancel) on left and red **stop** square on right.
5. **Processing**: bars collapse to a pulsing dot row / shimmer *(est. 600 ms loop)*. Hold-mode shows cancel after ~3 s.
6. **Command Mode**: same pill, distinct accent (purple glow) and label.
7. **Error / notice**: toast card next to bar with title, body, action buttons (Retry, Copy, Open History, Go to settings, Insert).
Behavior: drag to bottom, left or right edge dock; position remembered. Right-click at rest: Hide for 1 hour, Microphone submenu ("Mic in use"), languages. Setting "Show Flow Bar at all times". Floats above all windows and full-screen spaces, never takes focus. Animations: expand/collapse spring *(est. response 0.35, damping 0.8)*.

## 4. Hub (main window)

Sidebar (top to bottom): **Home, Meetings\*, Insights, Dictionary, Snippets, Style, Transforms, Notes/Scratchpad, Tasks\*, Extensions\***; bottom: **Settings, Help** (+ plan/usage badge). (\* out of scope.)

- **Home**: greeting, stats strip (words this week, WPM, streak), then transcript **History** grouped by date (Today, Yesterday, date), newest first. Row: time, text, app icon. Hover actions: Copy, Play audio (last 14 days), ⋯ menu: Undo AI edit / Redo, Retry (failed rows orange: "Retry your X:XX transcript"), Report, Delete.
- **Dictionary**: list of words; Add word (term, optional "sounds like"/misspelling to replace), star important words, sort by usage, search, edit/delete. Auto-add when user corrects a pasted word (filters apostrophe variants).
- **Snippets**: cue phrase -> expansion (rich text: bold, italic, links, lists). Saying the cue inserts the full text.
- **Style**: per-category writing style for **Personal messages, Work messages, Email, Other**; options **Formal.** (caps + full punctuation), **Casual** (caps, lighter punctuation), **very casual** (no caps, minimal punctuation), **Excited!** (exclamation). Preview bubbles per option. Category picked by frontmost app/website (Slack/Teams = Work, iMessage/WhatsApp/Discord/Signal/Instagram = Personal, Mail/Gmail/Outlook/Missive = Email with greeting/sign-off/line breaks). English only. Trailing-period removal rules per style in messaging apps. **Auto Cleanup** level: None / Light / Medium / High.
- **Transforms** (beta): select text + shortcut or wand -> rewrite. Built-ins: **Polish**, **Prompt Engineer**; custom prompts; optionally auto-run after every dictation.
- **Insights**: Your Usage (WPM vs others, total words, words cleaned, smart replacements, top apps, streak heatmap); Your Voice (archetype, catchphrase, most corrected word, active hours; unlocks at 2,000 words); Leaderboard (teams).
- **Notes / Scratchpad** (beta): floating notepad, Opt+S. Out of scope v1.

## 5. AI editing behaviors

- Remove fillers (um, uh, like, you know), collapse stutters.
- Auto punctuation and capitalization; paragraphs.
- Numbered / bulleted lists when speaker enumerates ("one ... two ...", "first, second").
- **Backtrack**: genuine corrections keep only the replacement ("Tuesday, no wait, Wednesday" -> "Wednesday"); "scratch that" deletes retracted words. "actually" alone and "never mind" inside content are kept.
- Spoken punctuation / formatting ("new line", "comma", "period").
- Context awareness: reads surrounding text / names on screen to spell names; continues sentences.
- Developer mode: file tagging (`@file.ts` in Cursor/Windsurf), code syntax, camelCase/snake_case terms; terminal apps keep long dictations visible (avoid "[Pasted N lines]" collapse).
- Email formatting in email category.
- Whisper support, 100+ languages, auto-detect or selected languages; language picker in bar.

## 6. Command Mode (Settings → Experimental, off by default; Pro only)

Hold Fn+Ctrl, speak instruction, release. Sends field contents + selection with instruction. Results pasted raw (replaces selection). With no editable field, result shown in notification. Search commands open a web search with selection. Double-press within 500 ms locks hands-free. Esc/Backspace cancels. Messages: "Using Command Mode (beta)" one-time notice with Disable; "Command mode is toggled off" (max 3x, 1/day); "Transcript currently processing"; "Command Mode Servers Are Busy".

## 7. Onboarding (desktop)

1. Welcome / sign-in (Google, Apple, email, SSO, "Sign in via browser"); motion slides.
2. About you (role / use case), languages.
3. Permissions: **Microphone**, **Accessibility** (required to insert; "Not now" allowed). Screen Recording optional for context. Steps skip when already granted. Buttons open matching System Settings pane.
4. Test your microphone: live level bars; **Change microphone**, **Find the right mic for you**; errors No microphone found / In use by another app.
5. Shortcut: detect Apple Fn key; else apply fallback set. Optionally recommend Ctrl+Space.
6. Practice: hold Fn and say a sample sentence in a built-in practice field; then hands-free practice; then backtrack / list demos.
7. Style personalization (categories).
8. Data preferences (Privacy Mode, Cloud Sync), notifications.
9. Done: Flow Bar appears.

## 8. Settings

- **General**: Shortcuts (Change), Microphone (Change, ranking, auto-select, clamshell handling, Show other devices), Dictation languages (auto-detect, multi-select, Canadian English nudge), App language.
- **System**: Launch at login, Show app in Dock, Show Flow Bar at all times, Sound effects (start/stop), Mute music while dictating, Scratchpad open behavior.
- **Notifications**: per-category mutes (feature tips, formatting reminders, milestones, announcements).
- **Experimental**: Command Mode, others.
- **Data & Privacy**: Privacy Mode (no training), Cloud Sync, Local data storage (Normal / auto-delete after 24 h / Never store), audio removed after 14 days, delete history.
- **Account**, **Plans & Billing** (sync button), **Team**.
- Menu bar icon menu: Open Flow, Shortcuts, Paste last transcript, Microphone, Help, Check for updates, Quit.

## 9. Microphone handling

Ranked list, auto picks highest available; hot-swap mid-dictation; virtual devices behind "Show other devices"; new mic prompt "Switch / Don't switch"; clamshell warning when using built-in mic with lid closed. Error notices: Selected microphone is unavailable, No microphone detected, Microphone unavailable, Unable to access mic (Restart App), mic disconnected (Insert captured text).

## 10. Design tokens (from wisprflow.ai CSS; app chrome is close to the site)

| Token | Value | Use |
|---|---|---|
| lumen | #FFFFEB | cream background |
| lumen-dark | #E4E4D0 | dividers, hover |
| off-white | #FFFDF9 / #F5F4F0 | cards |
| vast | #1A1A1A | text, Flow Bar body |
| neutral | #71716E | secondary text |
| dawn | #F0D7FF | lavender accent / selected sidebar |
| signal | #FFBCF2 | pink accent |
| flare | #FF6C4C | orange (failed / warning rows) |
| glow | #FFA946 | |
| fathom | #034F46 | deep green |
| pulse | #7F1C34 | error dark |
| success | #CEF5CA / #114E0B | |
| warning | #FCF8D8 / #5E5515 | |
| error | #F8E4E4 | |
| focus | #2D62FF | focus ring |
| border | #1A1A1A at 30% | |

Fonts: Wispr uses EB Garamond (display serif) + Figtree (body). **Clone uses DM Sans everywhere** (bundled, OFL). Radii *(est.)*: cards 12, buttons 8 / pill 999, Flow Bar full-pill. Shadow on bar: 0 4 16 rgba(0,0,0,0.25).

## 11. Platform matrix

| Feature | Mac | Windows | iOS | Android |
|---|---|---|---|---|
| Dictation in any app | ✓ Flow Bar | ✓ Flow Bar | Keyboard | Bubble |
| Styles by app | ✓ | ✓ | default only (iOS 26.4) | ✓ |
| Command Mode | ✓ | ✓ | search only | — |
| Snippets / Dictionary | ✓ | ✓ | ✓ | ✓ |
| Transforms, Scratchpad | ✓ | ✓ | Notes | — |
| Notetaker | ✓ | ✓ | — | — |
| Mouse buttons | ✓ (4-10) | ✓ (4-5) | | |
Clone v1: Mac only (macOS 14.2+, matching MyMan).

## 12. Pricing (Wispr)

Free: 2,000 words/week desktop, 1,000 mobile; dictionary + snippets; limited Notetaker. Pro: $15/user/mo ($12 annual): unlimited, Command Mode, teams. Growth / Enterprise: $23-33 tiers, SSO, HIPAA. 50% student discount. **WisprFlowIsDead: free, no limits, no account, Apache-2.0, fully on-device.**

## 13. Clone mapping

| Wispr | WisprFlowIsDead |
|---|---|
| Cloud ASR (Canto) | On-device Parakeet / Qwen3 / Apple SpeechAnalyzer (vendored from MyMan) |
| Cloud LLM cleanup | Deterministic cleanup + Apple Foundation Models (macOS 26) from MyMan |
| Command Mode cloud LLM | Apple Foundation Models on-device (macOS 26), off by default |
| Account / sync / teams | None |
