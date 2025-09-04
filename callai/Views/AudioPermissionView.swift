import SwiftUI

/// SwiftUI view for handling audio permission requests
struct AudioPermissionView: View {
    @ObservedObject var audioManager: AudioRecordingManager
    @State private var isRequestingPermission = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Permission status indicator
            permissionStatusView
            
            // Action button
            actionButton
            
            // Error message if any
            if let errorMessage = audioManager.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    @ViewBuilder
    private var permissionStatusView: some View {
        switch audioManager.permissionStatus {
        case .notDetermined:
            VStack {
                Image(systemName: "mic.circle")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                
                Text("Microphone Access Required")
                    .font(.headline)
                
                Text("CallAI needs access to your microphone to record meeting audio.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            
        case .granted:
            VStack {
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green)
                
                Text("Microphone Access Granted")
                    .font(.headline)
                    .foregroundColor(.green)
                
                Text("Ready to record meeting audio.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
        case .denied:
            VStack {
                Image(systemName: "mic.slash.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.red)
                
                Text("Microphone Access Denied")
                    .font(.headline)
                    .foregroundColor(.red)
                
                Text("Please enable microphone access in System Settings to record meetings.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private var actionButton: some View {
        switch audioManager.permissionStatus {
        case .notDetermined:
            Button(action: requestPermission) {
                HStack {
                    if isRequestingPermission {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text(isRequestingPermission ? "Requesting..." : "Allow Microphone Access")
                }
                .frame(minWidth: 200)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRequestingPermission)
            
        case .granted:
            Button("Test Microphone") {
                // Optional: Add test functionality
            }
            .buttonStyle(.bordered)
            
        case .denied:
            Button("Open System Settings") {
                openSystemSettings()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private func requestPermission() {
        isRequestingPermission = true
        
        Task {
            await audioManager.requestPermission()
            
            await MainActor.run {
                isRequestingPermission = false
            }
        }
    }
    
    private func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Preview
struct AudioPermissionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AudioPermissionView(audioManager: AudioRecordingManager())
                .previewDisplayName("Not Determined")
            
            AudioPermissionView(audioManager: {
                let manager = AudioRecordingManager()
                // Note: In real preview, we can't modify the permission status
                return manager
            }())
            .previewDisplayName("Permission Flow")
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }
}