import Cocoa
import Carbon

class KeyboardShortcutManager: ObservableObject {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    var onShortcutPressed: (() -> Void)?
    
    // Target modifier combination: Ctrl+Alt+Cmd+Shift
    private let targetModifiers: CGEventFlags = [.maskControl, .maskAlternate, .maskCommand, .maskShift]
    
    // Debouncing to prevent rapid-fire triggering
    private var lastTriggerTime: TimeInterval = 0
    private let debounceInterval: TimeInterval = 0.5 // 500ms
    
    init() {
        Logger.shared.info("KeyboardShortcutManager: Initializing")
        setupGlobalKeyListener()
    }
    
    private func setupGlobalKeyListener() {
        Logger.shared.info("KeyboardShortcutManager: Setting up global key listener")
        // Check accessibility permissions
        guard AXIsProcessTrusted() else {
            Logger.shared.warn("KeyboardShortcutManager: Accessibility permissions not granted")
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
            Logger.shared.error("KeyboardShortcutManager: Failed to create event tap")
            return
        }
        
        Logger.shared.info("KeyboardShortcutManager: Event tap created successfully")
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        Logger.shared.info("KeyboardShortcutManager: Global key listener setup complete")
    }
    
    private func requestAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !trusted {
            print("Accessibility permissions not granted. Please enable in System Preferences.")
        }
    }
    
    private func handleKeyEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Check for our target modifier combination
        let eventFlags = event.flags
        
        // Check if all four target modifiers are pressed
        if eventFlags.contains(targetModifiers) {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            Logger.shared.info("KeyboardShortcutManager: All modifiers (Ctrl+Alt+Cmd+Shift) detected with key \(keyCode), type: \(type.rawValue)")
            
            if type == .keyDown {
                // Debounce to prevent rapid-fire triggering
                let currentTime = Date().timeIntervalSince1970
                if currentTime - lastTriggerTime > debounceInterval {
                    Logger.shared.info("KeyboardShortcutManager: Modifier combination pressed - triggering shortcut")
                    lastTriggerTime = currentTime
                    onShortcutPressed?()
                } else {
                    Logger.shared.info("KeyboardShortcutManager: Modifier combination ignored (debounced)")
                }
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