import Foundation

class TranscriptionService: ObservableObject {
    private var pythonProcess: Process?
    private var inputPipe: Pipe?
    private var outputPipe: Pipe?
    
    var onTranscriptionComplete: (([String: Any]) -> Void)?
    
    @Published var isInitialized = false
    @Published var isProcessing = false
    
    init() {
        startPythonServer()
    }
    
    private func startPythonServer() {
        // Find the Python script path relative to the app bundle
        guard let bundlePath = Bundle.main.bundlePath else {
            print("Failed to get bundle path")
            return
        }
        
        let pythonScriptPath = "\(bundlePath)/../../../python/transcription_server.py"
        
        // Create pipes for communication
        inputPipe = Pipe()
        outputPipe = Pipe()
        
        // Set up the process
        pythonProcess = Process()
        pythonProcess?.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        pythonProcess?.arguments = ["uv", "run", "python", pythonScriptPath]
        pythonProcess?.standardInput = inputPipe
        pythonProcess?.standardOutput = outputPipe
        
        // Set up working directory to the project root
        let projectRoot = "\(bundlePath)/../../.."
        pythonProcess?.currentDirectoryURL = URL(fileURLWithPath: projectRoot)
        
        // Start monitoring output
        setupOutputMonitoring()
        
        do {
            try pythonProcess?.run()
            print("Python transcription server started")
            
            // Send ping to verify connection
            sendCommand(["action": "ping"])
            
        } catch {
            print("Failed to start Python server: \(error)")
        }
    }
    
    private func setupOutputMonitoring() {
        guard let outputPipe = outputPipe else { return }
        
        outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if !data.isEmpty {
                let output = String(data: data, encoding: .utf8) ?? ""
                self?.handlePythonOutput(output)
            }
        }
    }
    
    private func handlePythonOutput(_ output: String) {
        let lines = output.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        for line in lines {
            do {
                let json = try JSONSerialization.jsonObject(with: line.data(using: .utf8)!, options: [])
                if let response = json as? [String: Any] {
                    handlePythonResponse(response)
                }
            } catch {
                print("Failed to parse JSON response: \(line)")
            }
        }
    }
    
    private func handlePythonResponse(_ response: [String: Any]) {
        if let message = response["message"] as? String, message == "pong" {
            DispatchQueue.main.async {
                self.isInitialized = true
            }
            print("Python server is ready")
        } else if response["success"] != nil || response["error"] != nil {
            // This is a transcription response
            DispatchQueue.main.async {
                self.isProcessing = false
                self.onTranscriptionComplete?(response)
            }
        }
    }
    
    func transcribe(audioPath: String) {
        guard isInitialized, !isProcessing else {
            print("Cannot transcribe: server not ready or already processing")
            return
        }
        
        isProcessing = true
        
        let command = [
            "action": "transcribe",
            "audio_path": audioPath
        ]
        
        sendCommand(command)
    }
    
    private func sendCommand(_ command: [String: Any]) {
        guard let inputPipe = inputPipe else {
            print("Input pipe not available")
            return
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: command, options: [])
            let jsonString = String(data: jsonData, encoding: .utf8)! + "\n"
            
            inputPipe.fileHandleForWriting.write(jsonString.data(using: .utf8)!)
            
        } catch {
            print("Failed to send command: \(error)")
        }
    }
    
    func cleanup() {
        if let process = pythonProcess, process.isRunning {
            // Send quit command
            sendCommand(["action": "quit"])
            
            // Give it a moment to shut down gracefully
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                if process.isRunning {
                    process.terminate()
                }
            }
        }
        
        inputPipe = nil
        outputPipe = nil
        pythonProcess = nil
        
        print("Transcription service cleaned up")
    }
    
    deinit {
        cleanup()
    }
}