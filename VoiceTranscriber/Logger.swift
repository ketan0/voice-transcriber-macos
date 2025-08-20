import Foundation

class Logger {
    static let shared = Logger()
    private let logFilePath = "/tmp/voice_transcriber.log"
    private let dateFormatter: DateFormatter
    
    private init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss,SSS"
    }
    
    func log(_ message: String, level: String = "INFO") {
        let timestamp = dateFormatter.string(from: Date())
        let logMessage = "\(timestamp) - SWIFT-\(level) - \(message)\n"
        
        // Print to console for debugging
        print("[SWIFT-\(level)] \(message)")
        
        // Write to log file
        if let data = logMessage.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logFilePath) {
                if let fileHandle = FileHandle(forWritingAtPath: logFilePath) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                FileManager.default.createFile(atPath: logFilePath, contents: data, attributes: nil)
            }
        }
    }
    
    func info(_ message: String) {
        log(message, level: "INFO")
    }
    
    func debug(_ message: String) {
        log(message, level: "DEBUG")
    }
    
    func error(_ message: String) {
        log(message, level: "ERROR")
    }
    
    func warn(_ message: String) {
        log(message, level: "WARN")
    }
}