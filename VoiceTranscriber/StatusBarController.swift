import Cocoa
import SwiftUI

class StatusBarController: ObservableObject {
    private var statusItem: NSStatusItem
    private var audioRecorder: AudioRecorder
    private var transcriptionService: TranscriptionService
    private var keyboardShortcutManager: KeyboardShortcutManager
    private var textInputService: TextInputService
    
    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var lastTranscription = ""
    
    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        audioRecorder = AudioRecorder()
        transcriptionService = TranscriptionService()
        keyboardShortcutManager = KeyboardShortcutManager()
        textInputService = TextInputService()
        
        setupStatusItem()
        setupKeyboardShortcuts()
        setupObservers()
    }
    
    private func setupStatusItem() {
        if let statusButton = statusItem.button {
            statusButton.image = NSImage(systemSymbolName: "mic", accessibilityDescription: "Voice Transcriber")
            statusButton.action = #selector(statusItemClicked)
            statusButton.target = self
        }
        
        updateStatusItemAppearance()
        setupMenu()
    }
    
    private func setupMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: isRecording ? "Stop Recording" : "Start Recording", 
                                action: #selector(toggleRecording), 
                                keyEquivalent: ""))
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(title: "Settings...", 
                                action: #selector(openSettings), 
                                keyEquivalent: ","))
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(title: "Quit Voice Transcriber", 
                                action: #selector(quit), 
                                keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    private func setupKeyboardShortcuts() {
        keyboardShortcutManager.onShortcutPressed = { [weak self] in
            DispatchQueue.main.async {
                self?.toggleRecording()
            }
        }
    }
    
    private func setupObservers() {
        audioRecorder.onRecordingStateChanged = { [weak self] isRecording in
            DispatchQueue.main.async {
                self?.isRecording = isRecording
                self?.updateStatusItemAppearance()
                self?.setupMenu()
            }
        }
        
        transcriptionService.onTranscriptionComplete = { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessing = false
                self?.updateStatusItemAppearance()
                
                if let text = result["text"] as? String, !text.isEmpty {
                    self?.lastTranscription = text
                    self?.textInputService.insertText(text)
                }
            }
        }
    }
    
    private func updateStatusItemAppearance() {
        guard let statusButton = statusItem.button else { return }
        
        if isProcessing {
            statusButton.image = NSImage(systemSymbolName: "waveform.circle", accessibilityDescription: "Processing")
        } else if isRecording {
            statusButton.image = NSImage(systemSymbolName: "record.circle.fill", accessibilityDescription: "Recording")
        } else {
            statusButton.image = NSImage(systemSymbolName: "mic", accessibilityDescription: "Voice Transcriber")
        }
    }
    
    @objc private func statusItemClicked() {
        toggleRecording()
    }
    
    @objc private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        guard !isRecording && !isProcessing else { return }
        audioRecorder.startRecording()
    }
    
    private func stopRecording() {
        guard isRecording else { return }
        
        if let audioPath = audioRecorder.stopRecording() {
            isProcessing = true
            updateStatusItemAppearance()
            transcriptionService.transcribe(audioPath: audioPath)
        }
    }
    
    @objc private func openSettings() {
        if #available(macOS 13.0, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }
    
    @objc private func quit() {
        NSApp.terminate(nil)
    }
    
    func cleanup() {
        audioRecorder.cleanup()
        transcriptionService.cleanup()
        keyboardShortcutManager.cleanup()
    }
}