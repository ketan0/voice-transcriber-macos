import Cocoa
import Carbon

class TextInputService {
    
    init() {
        checkAccessibilityPermissions()
    }
    
    private func checkAccessibilityPermissions() {
        guard AXIsProcessTrusted() else {
            print("Accessibility permissions required for text input")
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
            AXIsProcessTrustedWithOptions(options as CFDictionary)
            return
        }
    }
    
    func insertText(_ text: String) {
        Logger.shared.info("TextInputService: insertText called with text: '\(text)'")
        guard AXIsProcessTrusted() else {
            Logger.shared.error("TextInputService: Cannot insert text - Accessibility permissions not granted")
            return
        }
        
        // Get the currently focused application
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            Logger.shared.error("TextInputService: No frontmost application found")
            return
        }
        
        Logger.shared.info("TextInputService: Inserting text into: \(frontmostApp.localizedName ?? "Unknown")")
        
        // Try smart insertion methods in order of reliability
        Logger.shared.info("TextInputService: Attempting insertion via pasteboard (Cmd+V)")
        if insertTextViaPasteboard(text) {
            Logger.shared.info("TextInputService: Text inserted successfully via pasteboard")
        } else {
            Logger.shared.info("TextInputService: Pasteboard failed, trying key events")
            insertTextViaKeyEvents(text)
        }
    }
    
    private func insertTextViaPasteboard(_ text: String) -> Bool {
        Logger.shared.info("TextInputService: Using pasteboard method")
        
        // Save current clipboard contents
        let pasteboard = NSPasteboard.general
        let savedClipboardItems = pasteboard.pasteboardItems
        
        // Clear pasteboard and set our text
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // Small delay to ensure pasteboard is updated
        usleep(10_000) // 10ms
        
        // Simulate Cmd+V
        let success = simulateCommandV()
        
        // Restore original clipboard after a short delay
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            pasteboard.clearContents()
            if let savedItems = savedClipboardItems {
                pasteboard.writeObjects(savedItems)
            }
        }
        
        return success
    }
    
    private func simulateCommandV() -> Bool {
        // Create Cmd+V key event
        guard let keyDownEvent = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: true),
              let keyUpEvent = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: false) else {
            Logger.shared.error("TextInputService: Failed to create Cmd+V events")
            return false
        }
        
        // Set command modifier
        keyDownEvent.flags = .maskCommand
        keyUpEvent.flags = .maskCommand
        
        // Post the events
        keyDownEvent.post(tap: .cghidEventTap)
        usleep(10_000) // 10ms delay between key down and up
        keyUpEvent.post(tap: .cghidEventTap)
        
        Logger.shared.info("TextInputService: Cmd+V simulated")
        return true
    }
    
    private func insertTextViaAccessibility(_ text: String) -> Bool {
        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElement: CFTypeRef?
        
        let result = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        
        guard result == .success, let element = focusedElement else {
            print("Failed to get focused UI element")
            return false
        }
        
        let axElement = element as! AXUIElement
        
        // Try to set the value directly
        let textValue = text as CFString
        let setResult = AXUIElementSetAttributeValue(axElement, kAXValueAttribute as CFString, textValue)
        
        if setResult == .success {
            print("Successfully inserted text via AX value attribute")
            return true
        }
        
        // If setting value directly fails, try to get current value and append
        var currentValue: CFTypeRef?
        let getCurrentResult = AXUIElementCopyAttributeValue(axElement, kAXValueAttribute as CFString, &currentValue)
        
        if getCurrentResult == .success, let current = currentValue as? String {
            let newValue = current + text
            let newTextValue = newValue as CFString
            let appendResult = AXUIElementSetAttributeValue(axElement, kAXValueAttribute as CFString, newTextValue)
            
            if appendResult == .success {
                print("Successfully appended text via AX value attribute")
                return true
            }
        }
        
        print("Failed to insert text via Accessibility API")
        return false
    }
    
    private func insertTextViaKeyEvents(_ text: String) {
        print("Inserting text via key events")
        
        // Small delay to ensure the target application is ready
        usleep(50_000) // 50ms
        
        for character in text {
            sendKeyEvent(for: character)
            usleep(10_000) // 10ms delay between characters
        }
    }
    
    private func sendKeyEvent(for character: Character) {
        let string = String(character)
        
        // Create the key down event
        guard let keyDownEvent = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true) else {
            return
        }
        
        // Set the unicode string for the event
        keyDownEvent.keyboardSetUnicodeString(stringLength: string.count, unicodeString: Array(string.utf16))
        
        // Create the key up event
        guard let keyUpEvent = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false) else {
            return
        }
        
        keyUpEvent.keyboardSetUnicodeString(stringLength: string.count, unicodeString: Array(string.utf16))
        
        // Post the events
        keyDownEvent.post(tap: .cghidEventTap)
        keyUpEvent.post(tap: .cghidEventTap)
    }
    
    // Alternative method using CGEventCreateKeyboardEvent for special characters
    private func sendKeyCode(_ keyCode: CGKeyCode, modifiers: CGEventFlags = []) {
        let keyDownEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)
        let keyUpEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
        
        keyDownEvent?.flags = modifiers
        keyUpEvent?.flags = modifiers
        
        keyDownEvent?.post(tap: .cghidEventTap)
        keyUpEvent?.post(tap: .cghidEventTap)
    }
}