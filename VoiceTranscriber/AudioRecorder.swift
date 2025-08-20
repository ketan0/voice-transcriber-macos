import AVFoundation
import Foundation

class AudioRecorder: NSObject, ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    
    var onRecordingStateChanged: ((Bool) -> Void)?
    
    @Published var isRecording = false
    @Published var hasPermission = true // macOS handles permissions differently
    
    override init() {
        super.init()
        checkPermissions()
    }
    
    private func checkPermissions() {
        // On macOS, check microphone permission using AVCaptureDevice
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            hasPermission = true
        case .denied, .restricted:
            hasPermission = false
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.hasPermission = granted
                }
            }
        @unknown default:
            hasPermission = false
        }
    }
    
    func startRecording() {
        Logger.shared.info("AudioRecorder: startRecording called")
        guard hasPermission else {
            Logger.shared.error("AudioRecorder: Recording permission not granted")
            return
        }
        
        guard !isRecording else {
            Logger.shared.warn("AudioRecorder: Already recording")
            return
        }
        
        // Create temporary file for recording
        let tempDirectory = FileManager.default.temporaryDirectory
        recordingURL = tempDirectory.appendingPathComponent("voice_recording_\(UUID().uuidString).wav")
        
        guard let url = recordingURL else {
            print("Failed to create recording URL")
            return
        }
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ] as [String: Any]
        
        do {
            Logger.shared.info("AudioRecorder: Creating AVAudioRecorder with settings")
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            
            Logger.shared.info("AudioRecorder: Starting recording")
            audioRecorder?.record()
            
            isRecording = true
            onRecordingStateChanged?(true)
            
            Logger.shared.info("AudioRecorder: Recording started successfully to: \(url.path)")
        } catch {
            Logger.shared.error("AudioRecorder: Failed to start recording: \(error)")
        }
    }
    
    func stopRecording() -> String? {
        Logger.shared.info("AudioRecorder: stopRecording called")
        guard isRecording, let recorder = audioRecorder else {
            Logger.shared.warn("AudioRecorder: Not currently recording")
            return nil
        }
        
        Logger.shared.info("AudioRecorder: Stopping recording")
        recorder.stop()
        isRecording = false
        onRecordingStateChanged?(false)
        
        let recordingPath = recordingURL?.path
        Logger.shared.info("AudioRecorder: Recording stopped. File saved to: \(recordingPath ?? "unknown")")
        
        return recordingPath
    }
    
    func cleanup() {
        if isRecording {
            _ = stopRecording()
        }
        
        // Clean up old recording files
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Recording finished unsuccessfully")
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("Recording error: \(error)")
        }
    }
}