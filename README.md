# VoiceInput

VoiceInput is a macOS menu-bar app for fast voice input.

- Hold `Fn`, speak, release: the recognized text is pasted into the focused input field.
- Hold `Option` during the `Fn` recording session: the recognized text is translated by an OpenAI-compatible LLM, then pasted into the focused input field.

The app uses Apple's built-in speech recognition for local speech-to-text, and a configurable OpenAI-compatible API for translation.

## Features

- Real-time speech recognition with Apple's `SFSpeechRecognizer`
- Direct text injection into the currently focused text field
- Translation mode triggered by `Option + Fn`
- Configurable target language
- OpenAI-compatible translation API settings
- Translation history persistence
- Keychain storage for API keys

## Requirements

- macOS 14.0 or later
- Xcode Command Line Tools
- Accessibility permission
- Microphone permission
- Speech Recognition permission

## Build

```bash
make build
```

This builds the release binary and assembles `VoiceInput.app` in the repository root.

Other commands:

```bash
make run
make install
make clean
swift build -c release
```

## Usage

### Dictation

1. Focus any text input field.
2. Hold `Fn`.
3. Speak.
4. Release `Fn`.

The recognized text will be pasted into the active field.

### Translation

1. Open `Translation > Settings...`
2. Configure:
   - `Target Language`
   - `LLM API`
     - `Base URL`
     - `API Key`
     - `Model`
3. Focus any text input field.
4. Hold `Fn`, and during the recording session hold `Option`.
5. Release `Fn`.

The recognized speech will be translated and pasted into the active field.

## Permissions

VoiceInput needs three macOS permissions:

- `Accessibility`
  Required for global key monitoring and text injection.
- `Microphone`
  Required for recording speech.
- `Speech Recognition`
  Required for Apple's built-in transcription.

If `Accessibility` is granted after first launch, restart the app.

## Translation Settings

Current translation mode is intentionally simple:

- one settings window
- one target language selector
- one OpenAI-compatible LLM configuration block

Supported translation setup fields:

- `Target Language`
- `Base URL`
- `API Key`
- `Model`

The `Test` button checks whether the current LLM configuration can translate a sample sentence successfully.

## Notes

- Translation currently uses only the OpenAI-compatible LLM path.
- The app keeps translation history on disk.
- API keys are stored in macOS Keychain.
- The source language follows the app's `Language` menu.

## Repository Notes

This repository is the distribution repo for VoiceInput.

The canonical upstream source is:

<https://github.com/yetone/voice-input-src>

This repo is intended to build reproducibly into the shipped `VoiceInput.app`.

## License

See the upstream source repository for license details.
