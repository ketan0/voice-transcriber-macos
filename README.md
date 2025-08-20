# Voice Transcriber

A macOS menu bar application that provides voice-to-text transcription using NVIDIA's Parakeet model via the parakeet-mlx library.

## Features

- **Menu Bar App**: Runs discreetly in the menu bar
- **Keyboard Shortcut**: Default Fn key to start/stop recording (configurable)
- **Local Processing**: Uses parakeet-mlx for on-device transcription
- **Text Insertion**: Automatically inserts transcribed text at cursor position
- **Multiple Models**: Support for different Parakeet model variants

## Requirements

- macOS 13.0 or later
- Python 3.8+ with uv package manager
- Microphone and Accessibility permissions

## Installation

1. **Install Dependencies**:
   ```bash
   cd voice-transcriber
   uv sync
   uv add parakeet-mlx
   ```

2. **Install ffmpeg** (required by parakeet-mlx):
   ```bash
   brew install ffmpeg
   ```

3. **Build the App**:
   - Open `VoiceTranscriber.xcodeproj` in Xcode
   - Build and run the project

## Setup

1. **Grant Permissions**:
   - **Microphone**: Required for audio recording
   - **Accessibility**: Required to insert text into other applications
   
   The app will prompt for these permissions on first run.

2. **Configure Shortcut**:
   - Access settings through the menu bar icon
   - Choose your preferred keyboard shortcut (default: Fn key)

## Usage

1. **Start Recording**: Press the configured shortcut key (default: Fn)
2. **Speak**: The menu bar icon will show recording status
3. **Stop Recording**: Press the shortcut key again
4. **Get Text**: Transcribed text will be automatically inserted at your cursor

## Architecture

- **Swift Frontend**: Handles UI, audio recording, and system integration
- **Python Backend**: Runs parakeet-mlx for ML transcription
- **IPC Communication**: JSON messages over stdin/stdout

## Project Structure

```
voice-transcriber/
├── VoiceTranscriber.xcodeproj
├── VoiceTranscriber/
│   ├── VoiceTranscriberApp.swift       # Main app entry
│   ├── StatusBarController.swift       # Menu bar management
│   ├── AudioRecorder.swift             # Audio recording
│   ├── TranscriptionService.swift      # Python process manager
│   ├── KeyboardShortcutManager.swift   # Global hotkey handling
│   ├── TextInputService.swift          # Text insertion
│   ├── SettingsView.swift              # Settings UI
│   └── Info.plist                      # Permissions
├── python/
│   ├── transcription_server.py         # Parakeet-mlx wrapper
│   └── requirements.txt
└── README.md
```

## Troubleshooting

1. **No Microphone Access**: Check Privacy & Security settings
2. **Text Not Inserting**: Grant Accessibility permissions
3. **Python Server Fails**: Ensure uv and parakeet-mlx are installed
4. **Model Download**: First transcription will download the model (may take time)

## Configuration

Settings are accessible through the menu bar icon:
- Model selection (different Parakeet variants)
- Keyboard shortcut customization
- Permission status

## Development

To modify or extend the app:

1. **Swift Code**: Edit files in `VoiceTranscriber/`
2. **Python Backend**: Modify `python/transcription_server.py`
3. **Dependencies**: Update `python/requirements.txt`

## License

This project uses the parakeet-mlx library under the Apache 2.0 license.