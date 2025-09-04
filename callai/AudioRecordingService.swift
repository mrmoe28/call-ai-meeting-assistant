import Foundation
import AVFoundation
import SwiftUI
import OSLog

// MARK: - Legacy compatibility wrapper
// This maintains compatibility with existing code while using the new AudioRecordingManager

private let logger = Logger(subsystem: "com.ekodev.callai", category: "AudioRecordingService")

enum RecordingPermissionStatus {
    case granted
    case denied
    case undetermined
    
    var modern: AudioPermissionStatus {
        switch self {
        case .granted: return .granted
        case .denied: return .denied
        case .undetermined: return .notDetermined
        }
    }
    
    init(from modern: AudioPermissionStatus) {
        switch modern {
        case .granted: self = .granted
        case .denied: self = .denied
        case .notDetermined: self = .undetermined
        }
    }
}

@MainActor
class AudioRecordingService: NSObject, ObservableObject {
    
    // MARK: - Legacy Published Properties
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var recordingLevel: Float = 0
    @Published var errorMessage: String?
    @Published var authorizationStatus: RecordingPermissionStatus = .undetermined
    
    // MARK: - Modern Implementation
    private let audioManager = AudioRecordingManager()
    
    override init() {
        super.init()
        logger.info("AudioRecordingService (legacy wrapper) initialized")
        setupBindings()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Bind modern implementation to legacy properties
        audioManager.$permissionStatus
            .map { RecordingPermissionStatus(from: $0) }
            .assign(to: &$authorizationStatus)
        
        audioManager.$isRecording
            .assign(to: &$isRecording)
        
        audioManager.$recordingDuration
            .assign(to: &$recordingDuration)
        
        audioManager.$audioLevel
            .assign(to: &$recordingLevel)
        
        audioManager.$errorMessage
            .assign(to: &$errorMessage)
    }
    
    // MARK: - Public Legacy Methods
    
    func checkRecordingPermission() {
        // This now happens automatically in the modern implementation
        logger.info("Permission check requested - status: \(String(describing: self.authorizationStatus))")
    }
    
    func refreshPermissionStatus() {
        logger.info("Permission status refresh requested")
        checkRecordingPermission()
    }
    
    func requestRecordingPermission() async {
        logger.info("Permission request via legacy interface")
        await audioManager.requestPermission()
    }
    
    func startRecording(for meeting: Meeting) async -> URL? {
        logger.info("Starting recording for meeting: \(meeting.title ?? "Untitled")")
        
        let fileName = "\(meeting.id.uuidString).m4a"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent(fileName)
        
        let success = await audioManager.startRecording(to: audioURL)
        
        if success {
            // Update meeting properties
            meeting.recordingURL = audioURL
            meeting.isRecorded = true
            meeting.updatedAt = Date()
            
            logger.info("Recording started successfully for meeting")
            return audioURL
        } else {
            logger.error("Failed to start recording for meeting")
            return nil
        }
    }
    
    func stopRecording() {
        logger.info("Stopping recording via legacy interface")
        audioManager.stopRecording()
    }
    
    // MARK: - Modern Interface Access
    
    /// Access to the modern audio recording manager
    var modern: AudioRecordingManager {
        return audioManager
    }
    
    // MARK: - Deprecated Methods (kept for compatibility)
    
    @available(*, deprecated, message: "Use modern AudioRecordingManager instead")
    func forceSystemPermissionDialog() async {
        logger.warning("Deprecated forceSystemPermissionDialog called")
        await requestRecordingPermission()
    }
    
    @available(*, deprecated, message: "Use modern AudioRecordingManager instead")
    func forcePermissionRequest() async {
        logger.warning("Deprecated forcePermissionRequest called")
        await requestRecordingPermission()
    }
    
    @available(*, deprecated, message: "Use modern AudioRecordingManager instead")
    func triggerMicrophoneUsage() async {
        logger.warning("Deprecated triggerMicrophoneUsage called")
        await requestRecordingPermission()
    }
}

// MARK: - Meeting Extension for Recording
extension Meeting {
    
    /// Start recording this meeting using the modern audio system
    /// - Parameter audioService: The audio recording service to use
    /// - Returns: The URL of the recording file if successful
    func startRecording(using audioService: AudioRecordingService) async -> URL? {
        return await audioService.startRecording(for: self)
    }
}