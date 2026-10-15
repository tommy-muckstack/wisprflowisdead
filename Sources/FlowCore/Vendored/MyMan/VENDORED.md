# Vendored from MyMan

Source: https://github.com/tommy-muckstack/myman (Apache-2.0)
Commit: af22e9e4e650aea99213eb354b96de0b4f519f15

FlowCore/Vendored/MyMan (pure Foundation, builds on Linux too):
- src/Voice/DictationCleanup.swift: unchanged except the built-in vocabulary list.
- src/Voice/DictationFormatting.swift: unchanged.
- src/Core/AsyncDeadline.swift: unchanged (used by the polish timeout).
- MyManShims.swift: new; stands in for MyMan's Brain (data folder) and People (no registry).

FlowVoice/Vendored/MyMan (macOS only):
- src/Voice/Transcription.swift, AudioCapture.swift, ModelLoadCoordinator.swift, Paste.swift: unchanged.
- Sources/AudioEngineSafety: copy of support/AudioEngineSafety.

To refresh: re-copy these files from a newer MyMan commit, re-apply the one-line
vocabulary edit, update the commit above, and run the tests.
