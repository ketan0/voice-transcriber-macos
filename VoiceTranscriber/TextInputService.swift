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
        guard AXIsProcessTrusted() else {
            print("Cannot insert text: Accessibility permissions not granted")
            return
        }
        
        // Get the currently focused application
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            print("No frontmost application found")
            return
        }
        
        print("Inserting text into: \(frontmostApp.localizedName ?? "Unknown")")
        
        // Try multiple methods to insert text
        if !insertTextViaAccessibility(text) {
            insertTextViaKeyEvents(text)
        }
    }
    
    private func insertTextViaAccessibility(_ text: String) -> Bool {
        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElement: CFTypeRef?
        
        let result = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute, &focusedElement)
        
        guard result == .success, let element = focusedElement else {
            print("Failed to get focused UI element")
            return false
        }
        
        let axElement = element as! AXUIElement
        
        // Try to set the value directly
        let textValue = text as CFString
        let setResult = AXUIElementSetAttributeValue(axElement, kAXValueAttribute, textValue)
        
        if setResult == .success {
            print("Successfully inserted text via AX value attribute")
            return true
        }
        
        // If setting value directly fails, try to get current value and append
        var currentValue: CFTypeRef?
        let getCurrentResult = AXUIElementCopyAttributeValue(axElement, kAXValueAttribute, &currentValue)
        
        if getCurrentResult == .success, let current = currentValue as? String {
            let newValue = current + text
            let newTextValue = newValue as CFString
            let appendResult = AXUIElementSetAttributeValue(axElement, kAXValueAttribute, newTextValue)
            
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