import Cocoa
import Carbon

class KeyboardShortcutManager: ObservableObject {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    var onShortcutPressed: (() -> Void)?
    
    // Default to Fn key
    private let targetKeyCode: CGKeyCode = 63 // kVK_Function
    
    init() {
        setupGlobalKeyListener()
    }
    
    private func setupGlobalKeyListener() {
        // Check accessibility permissions
        guard AXIsProcessTrusted() else {
            requestAccessibilityPermissions()
            return
        }
        
        // Create event tap
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
        
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) in
                let manager = Unmanaged<KeyboardShortcutManager>.fromOpaque(refcon!).takeUnretainedValue()
                return manager.handleKeyEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        
        guard let eventTap = eventTap else {
            print("Failed to create event tap")
            return
        }
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        print("Global key listener setup complete")
    }
    
    private func requestAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !trusted {
            print("Accessibility permissions not granted. Please enable in System Preferences.")
        }
    }
    
    private func handleKeyEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        
        // Check if it's our target key (Fn key)
        if keyCode == targetKeyCode {
            if type == .keyDown {
                // Fn key pressed
                onShortcutPressed?()
            }
            // Let the event continue (don't consume it)
            return Unmanaged.passUnretained(event)
        }
        
        // For all other keys, pass through unchanged
        return Unmanaged.passUnretained(event)
    }
    
    func cleanup() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
        }
        
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        
        print("Keyboard shortcut manager cleaned up")
    }
    
    deinit {
        cleanup()
    }
}