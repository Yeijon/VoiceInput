# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

VoiceInput is a macOS menu-bar app (Swift / SwiftPM, no external dependencies). Hold the **Fn key**, speak, release — Apple's on-device `SFSpeechRecognizer` transcribes the speech and the result is injected into the currently focused text field. An optional LLM pass can correct transcription errors before injection.

This is the **distribution repo**: it must build byte-for-identical to the published `VoiceInput.app` (the bundle is committed under `VoiceInput.app/`). The canonical source lives at <https://github.com/yetone/voice-input-src>. Keep `make build` reproducible — don't add network steps, timestamps, or non-deterministic inputs to the build.

## Commands

```bash
make build      # swift build -c release, then assemble + ad-hoc codesign VoiceInput.app
make run        # build, then `open VoiceInput.app`
make install    # build, then copy to /Applications
make clean      # swift package clean + remove VoiceInput.app
swift build -c release   # compile only (no .app bundle)
```

There is **no test suite** and no linter configured; `make build` is the only validation gate.

Regenerating the app icon (rarely needed — `VoiceInput.icns` is committed):
```bash
swift generate_icon.swift              # writes VoiceInput.iconset/
iconutil -c icns VoiceInput.iconset    # produces VoiceInput.icns
```

## Architecture

`AppDelegate` is the central coordinator — it owns every component and is the only place they interact. Components are decoupled via closure callbacks (`onPartialResult`, `onFnDown`, etc.); they never reference each other directly. When tracing a feature, start in `AppDelegate.swift`.

End-to-end flow of one dictation:

```
KeyMonitor (Fn down) → AppDelegate.fnDown → SpeechEngine.startRecording → OverlayPanel.show
SpeechEngine.onPartialResult → OverlayPanel.updateText   (live, as you speak)
KeyMonitor (Fn up)   → AppDelegate.fnUp   → SpeechEngine.stopRecording + start 2s fallback timer
finishTranscription  → [optional] LLMRefiner.refine → TextInjector.inject → OverlayPanel.dismiss
```

| File | Responsibility |
|------|----------------|
| `main.swift` | Entry point. Sets `.accessory` activation policy (menu-bar only, no Dock icon) and a minimal Edit menu so Cmd+C/V work in the Settings window. |
| `AppDelegate.swift` | Coordinator + state machine (`isEnabled`, `isRecording`), status-bar menu, language selection, the recording→refine→inject sequence. |
| `KeyMonitor.swift` | `CGEventTap` on `.flagsChanged` detecting the Fn modifier (`maskSecondaryFn`). |
| `SpeechEngine.swift` | `AVAudioEngine` + `SFSpeechRecognizer`. Streams audio, emits partial/final text, and computes a normalized audio level (RMS→dB) for the waveform. |
| `LLMRefiner.swift` | Singleton. Optional OpenAI-compatible `/chat/completions` call to fix STT errors. |
| `TextInjector.swift` | Pastes text into the focused field via clipboard + synthesized Cmd+V. |
| `OverlayPanel.swift` | Floating non-activating capsule HUD with an audio-driven waveform. |
| `SettingsWindow.swift` | Configures LLM base URL / API key / model, with a Test button. |

## Non-obvious behaviors

- **Three separate permissions.** Microphone and Speech Recognition are requested programmatically at launch (`SpeechEngine.requestPermissions`). **Accessibility cannot be** — it's required for the `CGEventTap`; if `keyMonitor.start()` returns `false`, the app shows an alert pointing to System Settings and quits. After granting Accessibility the app must be restarted.

- **Fn key is swallowed.** `KeyMonitor.handle` returns `nil` on Fn down/up to suppress the event, preventing the macOS emoji/dictation picker from appearing. It also re-enables the tap on `tapDisabledByTimeout`/`ByUserInput`.

- **2-second final-result fallback.** On Fn-up, `finalResultTimer` fires `finishTranscription` after 2s in case `SFSpeechRecognizer` never delivers an `isFinal` result. A real final result cancels the timer. Recognition error code `216` (cancellation) is intentionally ignored.

- **IME workaround in TextInjector.** If a non-ASCII input source (e.g. a Chinese IME) is active, Cmd+V would be intercepted, so it temporarily switches to an ASCII-capable layout (prefers `ABC`/`US`), pastes, then restores the original input source. It also saves and restores the user's clipboard. These steps use fixed `usleep`/`asyncAfter` delays — if injection becomes flaky, suspect timing here.

- **LLM refinement is off by default** and only runs when *both* enabled (menu toggle) and configured (non-empty API key). The system prompt is deliberately **conservative**: fix obvious recognition errors only (notably English/acronyms mis-rendered as Chinese, and Chinese homophones), never rephrase. Requests log to `~/Library/Logs/VoiceInput.log`.

- **Persistence.** All settings live in `UserDefaults` (`selectedLocaleCode` default `zh-CN`; `llmEnabled`, `llmAPIBaseURL`, `llmAPIKey`, `llmModel`). No config files.

## docs/voice-chat-design.md

A forward-looking design doc (in Chinese) for turning VoiceInput into a two-way voice **chat** assistant (TTS replies, conversation logging). It is **aspirational** — none of it is implemented yet. Do not treat it as a description of the current code.
