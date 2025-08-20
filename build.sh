#!/bin/bash

# Build script for Voice Transcriber
set -e

echo "🔨 Building Voice Transcriber for macOS..."

# Check if we're in the right directory
if [[ ! -f "VoiceTranscriber/VoiceTranscriberApp.swift" ]]; then
    echo "❌ Error: Run this script from the voice-transcriber directory"
    exit 1
fi

# Check for required tools
if ! command -v swiftc &> /dev/null; then
    echo "❌ Error: Swift compiler not found. Install Xcode Command Line Tools:"
    echo "   xcode-select --install"
    exit 1
fi

if ! command -v uv &> /dev/null; then
    echo "⚠️  Warning: uv not found. Installing..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
fi

if ! command -v ffmpeg &> /dev/null; then
    echo "⚠️  Warning: FFmpeg not found. Installing via Homebrew..."
    if command -v brew &> /dev/null; then
        brew install ffmpeg
    else
        echo "❌ Error: FFmpeg required but Homebrew not found."
        echo "   Install FFmpeg manually or install Homebrew first"
        exit 1
    fi
fi

echo "✅ Dependencies checked"

# Create app bundle structure
echo "📦 Creating app bundle..."
mkdir -p VoiceTranscriber.app/Contents/{MacOS,Resources}

# Create Info.plist
cat > VoiceTranscriber.app/Contents/Info.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDisplayName</key>
    <string>Voice Transcriber</string>
    <key>CFBundleExecutable</key>
    <string>VoiceTranscriber</string>
    <key>CFBundleIdentifier</key>
    <string>com.ketanagrawal.VoiceTranscriber</string>
    <key>CFBundleName</key>
    <string>Voice Transcriber</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>11.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSMicrophoneUsageDescription</key>
    <string>Voice Transcriber needs microphone access to record audio for transcription.</string>
</dict>
</plist>
EOF

# Compile Swift sources
echo "🏗️  Compiling Swift sources..."
cd VoiceTranscriber
swiftc -o VoiceTranscriber *.swift \
    -framework Cocoa \
    -framework SwiftUI \
    -framework AVFoundation \
    -framework Carbon

# Copy executable to app bundle
cp VoiceTranscriber ../VoiceTranscriber.app/Contents/MacOS/
cd ..

# Copy requirements.txt and Python files to app bundle
echo "📦 Copying Python files to app bundle..."
cp requirements.txt VoiceTranscriber.app/Contents/
cp -r python VoiceTranscriber.app/Contents/

echo "✅ Build completed successfully!"
echo ""
echo "🚀 To run the app:"
echo "   open VoiceTranscriber.app"
echo ""
echo "📋 Remember to grant Accessibility permissions:"
echo "   System Settings → Privacy & Security → Accessibility → Add VoiceTranscriber.app"