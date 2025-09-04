import Foundation
import AVFoundation
import SwiftUI
import OSLog
#if canImport(GrandAccess)
import GrandAccess
#endif

private let logger = Logger(subsystem: "com.ekodev.callai", category: "AudioRecording")

/// Modern audio recording permission status
enum AudioPermissionStatus {
    case notDetermined
    case granted
    case denied
}

/// Modern audio recording manager using Swift best practices
@MainActor
final class AudioRecordingManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var permissionStatus: AudioPermissionStatus = .notDetermined
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var audioLevel: Float = 0
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var levelTimer: Timer?
    private var recordingStartTime: Date?
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupAudioSession()
        checkPermissionStatus()
        logger.info("AudioRecordingManager initialized")
    }
    
    deinit {
        Task { @MainActor [weak self] in
            self?.stopRecording()
            self?.invalidateTimers()
        }
    }
    
    // MARK: - Public Methods
    
    /// Request microphone permission from the user
    func requestPermission() async {
        logger.info("Requesting microphone permission...")
        
        #if canImport(GrandAccess)
        let granted = await Permission.requestMicrophoneAccess
        await MainActor.run {
            self.permissionStatus = granted ? .granted : .denied
            logger.info("Permission result (GrandAccess): \(granted ? "granted" : "denied")")
        }
        #else
        let granted = await AVAudioApplication.requestRecordPermission()
        await MainActor.run {
            self.permissionStatus = granted ? .granted : .denied
            logger.info("Permission result: \(granted ? "granted" : "denied")")
        }
        #endif
    }
    
    /// Start recording audio to the specified URL
    /// - Parameter url: The file URL where audio should be saved
    /// - Returns: True if recording started successfully
    func startRecording(to url: URL) async -> Bool {
        logger.info("Attempting to start recording to: \(url.path)")
        
        // Check permission first
        if permissionStatus != .granted {
            await requestPermission()
            if permissionStatus != .granted {
                await setError("Microphone permission is required to record audio")
                return false
            }
        }
        
        // Stop any existing recording
        stopRecording()
        
        do {
            // Create recording settings
            let settings = createRecordingSettings()
            
            // Create and configure audio recorder
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            
            // Start recording
            let success = audioRecorder?.record() ?? false
            
            if success {
                isRecording = true
                recordingStartTime = Date()
                startTimers()
                logger.info("Recording started successfully")
                clearError()
                return true
            } else {
                await setError("Failed to start audio recording")
                logger.error("Failed to start recording")
                return false
            }
            
        } catch {
            await setError("Recording setup failed: \(error.localizedDescription)")
            logger.error("Recording setup failed: \(error)")
            return false
        }
    }
    
    /// Stop the current recording
    func stopRecording() {
        guard isRecording else { return }
        
        logger.info("Stopping recording")
        
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        recordingDuration = 0
        audioLevel = 0
        
        invalidateTimers()
        clearError()
        
        logger.info("Recording stopped")
    }
    
    // MARK: - Private Methods
    
    private func setupAudioSession() {
        #if os(iOS) || os(tvOS) || os(watchOS)
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
            logger.info("Audio session configured successfully")
        } catch {
            logger.error("Failed to setup audio session: \(error)")
        }
        #else
        // AVAudioSession is unavailable on macOS; no-op
        logger.info("Audio session setup skipped on this platform")
        #endif
    }
    
    private func checkPermissionStatus() {
        #if canImport(GrandAccess)
        Task { @MainActor in
            let isGranted = await Permission.isMicrophoneGranted
            self.permissionStatus = isGranted ? .granted : .denied
            switch AVAudioApplication.shared.recordPermission {
            case .undetermined:
                self.permissionStatus = .notDetermined
            default:
                break
            }
            logger.info("Current permission status (GrandAccess): \(self.permissionStatus)")
        }
        #else
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            permissionStatus = .granted
        case .denied:
            permissionStatus = .denied
        case .undetermined:
            permissionStatus = .notDetermined
        @unknown default:
            permissionStatus = .notDetermined
        }
        logger.info("Current permission status: \(String(describing: self.permissionStatus))")
        #endif
    }
    
    private func createRecordingSettings() -> [String: Any] {
        return [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
    }
    
    private func startTimers() {
        // Duration timer
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let startTime = self.recordingStartTime else { return }
                self.recordingDuration = Date().timeIntervalSince(startTime)
            }
        }
        
        // Audio level timer
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateAudioLevel()
            }
        }
    }
    
    private func invalidateTimers() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        levelTimer?.invalidate()
        levelTimer = nil
    }
    
    private func updateAudioLevel() {
        guard let recorder = audioRecorder, recorder.isRecording else {
            audioLevel = 0
            return
        }
        
        recorder.updateMeters()
        let power = recorder.averagePower(forChannel: 0)
        let normalizedLevel = max(0, (power + 60) / 60)
        audioLevel = Float(normalizedLevel)
    }
    
    private func setError(_ message: String) async {
        errorMessage = message
        logger.error("\(message)")
    }
    
    private func clearError() {
        errorMessage = nil
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioRecordingManager: AVAudioRecorderDelegate {
    
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            if !flag {
                await setError("Recording finished unsuccessfully")
            }
            logger.info("Recording finished, success: \(flag)")
        }
    }
    
    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            if let error = error {
                await setError("Recording error: \(error.localizedDescription)")
            }
        }
    }
}