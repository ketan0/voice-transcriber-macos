// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "VoiceTranscriber",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "VoiceTranscriber", targets: ["VoiceTranscriber"])
    ],
    targets: [
        .executableTarget(
            name: "VoiceTranscriber",
            path: "VoiceTranscriber",
            sources: [
                "VoiceTranscriberApp.swift",
                "StatusBarController.swift", 
                "AudioRecorder.swift",
                "KeyboardShortcutManager.swift",
                "TextInputService.swift",
                "TranscriptionService.swift",
                "SettingsView.swift"
            ]
        )
    ]
)