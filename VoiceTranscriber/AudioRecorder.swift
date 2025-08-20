import AVFoundation
import Foundation

class AudioRecorder: NSObject, ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private var recordingSession: AVAudioSession?
    private var recordingURL: URL?
    
    var onRecordingStateChanged: ((Bool) -> Void)?
    
    @Published var isRecording = false
    @Published var hasPermission = false
    
    override init() {
        super.init()
        setupAudioSession()
        checkPermissions()
    }
    
    private func setupAudioSession() {
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession?.setCategory(.record, mode: .default)
            try recordingSession?.setActive(true)
        } catch {
            print("Failed to set up recording session: \(error)")
        }
    }
    
    private func checkPermissions() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            hasPermission = true
        case .denied:
            hasPermission = false
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] allowed in
                DispatchQueue.main.async {
                    self?.hasPermission = allowed
                }
            }
        @unknown default:
            hasPermission = false
        }
    }
    
    func startRecording() {
        guard hasPermission else {
            print("Recording permission not granted")
            return
        }
        
        guard !isRecording else {
            print("Already recording")
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
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            
            isRecording = true
            onRecordingStateChanged?(true)
            
            print("Started recording to: \(url.path)")
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    func stopRecording() -> String? {
        guard isRecording, let recorder = audioRecorder else {
            print("Not currently recording")
            return nil
        }
        
        recorder.stop()
        isRecording = false
        onRecordingStateChanged?(false)
        
        let recordingPath = recordingURL?.path
        print("Stopped recording. File saved to: \(recordingPath ?? "unknown")")
        
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