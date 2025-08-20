# Voice Transcriber for macOS

A real-time voice transcription app for macOS that uses Apple's MLX framework and the Parakeet model to convert speech to text with high accuracy. Features global keyboard shortcuts and automatic text insertion.

## Features

- 🎤 **Real-time Voice Transcription** using MLX and Parakeet-TDT-0.6b-v2
- ⌨️ **Global Keyboard Shortcuts** (Ctrl+Alt+Cmd+Shift + any key)
- 📝 **Universal Text Insertion** works in all applications (Terminal, Emacs, Chrome, etc.)
- 🔄 **Menu Bar Integration** with visual recording status
- 🐍 **Automatic Python Setup** - no manual configuration required
- 🎯 **Smart Text Insertion** using clipboard and accessibility APIs
- ⚡ **Fast and Local** - all processing happens on-device

## Requirements

- **macOS 11.0+** (Big Sur or later)
- **Apple Silicon Mac** (M1/M2/M3) - required for MLX framework
- **FFmpeg** (automatically handled via Homebrew paths)
- **Accessibility permissions** for text insertion and keyboard shortcuts

## Installation

### Build from Source
1. Clone this repository:
   ```bash
   git clone https://github.com/ketanagrawal/voice-transcriber-macos.git
   cd voice-transcriber-macos
   ```

2. Install FFmpeg (if not already installed):
   ```bash
   brew install ffmpeg
   ```

3. Install uv (Python package manager):
   ```bash
   curl -LsSf https://astral.sh/uv/install.sh | sh
   ```

4. Build the app:
   ```bash
   ./build.sh
   ```

5. Run the built app:
   ```bash
   open VoiceTranscriber.app
   ```

## Setup

### First Launch
The app will automatically:
1. Create a Python 3.10 virtual environment
2. Install parakeet-mlx and dependencies
3. Download the Parakeet model (~150MB)

This process takes 1-2 minutes on first launch.

### Permissions Required
The app needs two types of permissions:

#### 1. Accessibility Permissions
For text insertion and keyboard shortcuts:
1. Go to **System Settings** → **Privacy & Security** → **Accessibility**
2. Click the **+** button and add `VoiceTranscriber.app`
3. Ensure it's checked/enabled

#### 2. Input Monitoring (Optional)
For global keyboard shortcuts:
1. Go to **System Settings** → **Privacy & Security** → **Input Monitoring**  
2. Add `VoiceTranscriber.app` if prompted

## Usage

### Recording Options
**Menu Bar:** Click the microphone icon → "Start Recording"
**Keyboard Shortcut:** Hold `Ctrl+Alt+Cmd+Shift` + press any key

### Recording Process
1. **Start Recording** - Icon turns orange, menu shows "Stop Recording"
2. **Speak** - Talk clearly into your microphone
3. **Stop Recording** - Click menu item or use keyboard shortcut again
4. **Transcription** - Text automatically appears where your cursor is

### Supported Applications
The transcriber works in all text input fields:
- **Terminals** (Terminal.app, iTerm2, etc.)
- **Text Editors** (Emacs, VS Code, Sublime Text, etc.)
- **Web Browsers** (Chrome, Safari, Firefox)
- **Chat Apps** (Slack, Discord, Messages)
- **Documents** (Word, Pages, Google Docs)
- **Code Editors** (Xcode, Cursor, etc.)

## How It Works

1. **Audio Capture** - Records high-quality audio using AVFoundation
2. **ML Transcription** - Uses Apple's MLX framework with Parakeet-TDT-0.6b-v2 model
3. **Text Insertion** - Smart insertion via clipboard (Cmd+V) with fallback to key events
4. **Cross-App Compatible** - Works universally across all macOS applications

## Project Structure

```
voice-transcriber/
├── VoiceTranscriber/           # Swift application source
│   ├── VoiceTranscriberApp.swift
│   ├── StatusBarController.swift
│   ├── AudioRecorder.swift
│   ├── TranscriptionService.swift
│   ├── TextInputService.swift
│   ├── KeyboardShortcutManager.swift
│   └── Logger.swift
├── python/                     # Python transcription server
│   └── transcription_server.py
├── requirements.txt            # Python dependencies
├── build.sh                   # Build script
└── README.md
```

## Configuration

### Keyboard Shortcut
The default shortcut is `Ctrl+Alt+Cmd+Shift + any key`. This is intentionally a complex combination to avoid conflicts with other applications.

### Model
The app uses `mlx-community/parakeet-tdt-0.6b-v2` for transcription. This model provides excellent accuracy for English speech and runs efficiently on Apple Silicon.

## Troubleshooting

### "Accessibility permissions not granted"
- Go to System Settings → Privacy & Security → Accessibility
- Add VoiceTranscriber.app and ensure it's enabled
- Restart the app after granting permissions

### "Python environment setup failed"
- Ensure you have internet connection for downloading dependencies
- Check that uv is installed: `which uv`
- Try deleting `.venv` folder and restarting the app

### "FFmpeg not found"
- Install FFmpeg: `brew install ffmpeg`
- Restart the app

### Text not inserting
- Grant Accessibility permissions
- Try using the menu bar option instead of keyboard shortcut
- Check that you're focused on a text input field

### Poor transcription quality
- Speak clearly and at moderate pace
- Ensure good microphone quality
- Record in a quiet environment
- Keep recordings under 30 seconds for best results

## Development

### Building
```bash
# Install dependencies
brew install ffmpeg
curl -LsSf https://astral.sh/uv/install.sh | sh

# Build
swiftc -o VoiceTranscriber VoiceTranscriber/*.swift \
    -framework Cocoa -framework SwiftUI \
    -framework AVFoundation -framework Carbon

# Create app bundle
mkdir -p VoiceTranscriber.app/Contents/MacOS
cp VoiceTranscriber VoiceTranscriber.app/Contents/MacOS/
```

### Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Acknowledgments

- **Apple MLX** - Machine learning framework for Apple Silicon
- **Parakeet-MLX** - Speech recognition model implementation
- **Hugging Face** - Model hosting and community

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Search [existing issues](https://github.com/ketanagrawal/voice-transcriber-macos/issues)
3. Create a new issue with:
   - macOS version
   - Mac model (M1/M2/M3)
   - Error logs from Console.app (search for "voice_transcriber")
   - Steps to reproduce

---

Built with ❤️ for the macOS community