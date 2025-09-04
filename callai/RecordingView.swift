import SwiftUI
import SwiftData

struct RecordingView: View {
    @StateObject private var audioService = AudioRecordingService()
    @StateObject private var transcriptionService = TranscriptionService()
    @StateObject private var summaryService = AISummaryService()
    @StateObject private var meetingSelectionManager = MeetingSelectionManager.shared
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedMeeting: Meeting?
    @State private var currentRecordingURL: URL?
    @State private var showingTranscriptionView = false
    @State private var permissionCheckTimer: Timer?
    @State private var showingCustomMeeting = false
    @State private var customMeetingTitle = ""
    @State private var customMeetingDate = Date()
    @State private var customMeetingDuration = 60.0
    @State private var selectedDeviceID: String = ""
    
    // Binding to parent tab selection to enable auto-navigation
    @Binding var selectedTab: Int
    
    private var meetingSidebar: some View {
                    MeetingSidebar(selectedMeeting: $selectedMeeting, selectedTab: $selectedTab)
                        .frame(height: 120)
                        .background(AppColor.surfaceElevated)
    }
                    
    private var mainContentArea: some View {
                    ScrollView {
                        LazyVStack(spacing: AppSpacing.sectionSpacing) {
                meetingSelectionView
                recordingControlsView
                devicePickerView
                permissionView
            }
        }
    }
    
    private var meetingSelectionView: some View {
        Group {
                        if let meeting = selectedMeeting {
                            SelectedMeetingView(meeting: meeting) {
                                selectedMeeting = nil
                            }
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            ))
                        } else {
                SelectMeetingPrompt(
                    onCreateMeeting: {
                        showingCustomMeeting = true
                    },
                    onViewCalendar: {
                        openCalendarApp()
                    }
                )
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            ))
            }
        }
    }
    
    private var devicePickerView: some View {
        Group {
            #if os(macOS)
            if checkRecordingPermission() {
                // Device picker temporarily disabled until device management APIs are implemented in AudioRecordingService
                EmptyView()
            }
            #endif
        }
    }
    
    private var recordingControlsView: some View {
                        RecordingControlsView(
                            isRecording: audioService.isRecording,
                            duration: audioService.recordingDuration,
                            level: audioService.recordingLevel,
            canRecord: selectedMeeting != nil && checkRecordingPermission(),
            selectedMeeting: selectedMeeting
                        ) {
                            await startRecording()
                        } stopAction: {
                            stopRecording()
        }
                        }
                        
    private var permissionView: some View {
        Group {
                        if !checkRecordingPermission() {
                if audioService.authorizationStatus == .denied {
                    deniedPermissionView
                } else {
                    undeterminedPermissionView
                }
            } else if selectedMeeting != nil {
                readyToRecordView
            }
        }
    }
    
    private var deniedPermissionView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: "mic.slash.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(.red.gradient)
                    .symbolEffect(.bounce, options: .repeating)
                
                VStack(spacing: 6) {
                    Text("Microphone Access Denied")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text("To enable recording, please grant microphone access in System Settings")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
            }
            
            permissionInstructionsView
            
            permissionActionButtons
        }
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(.red.opacity(0.3), lineWidth: 1)
        }
        .shadow(color: .red.opacity(0.1), radius: 8, x: 0, y: 2)
        .padding(20)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    private var undeterminedPermissionView: some View {
        VStack(spacing: 16) {
                            ModernPermissionBanner(
                                icon: "mic.fill",
                                title: "Microphone Access Required",
                                message: "Grant microphone access to record high-quality meeting audio",
                                buttonTitle: "Enable Microphone"
                            ) {
                                Task {
                                    // DRASTIC APPROACH: Force system dialog
                                    await audioService.forceSystemPermissionDialog()
                                    // Refresh status after request
                                    await MainActor.run {
                                        audioService.refreshPermissionStatus()
                                    }
                                }
            }
            
            #if os(macOS)
            VStack(alignment: .leading, spacing: 8) {
                Text("Tip: If you're using a USB interface like RØDECaster, select it as the input device once permission is granted.")
                    .font(AppFont.footnote)
                    .semanticForeground(AppColor.textMuted)
            }
            .padding(.horizontal, AppSpacing.xl)
            #endif
                            }
                            .padding(20)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    private var readyToRecordView: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text("Ready to Record")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            Text("Microphone access granted. Select a meeting above to start recording.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(.green.opacity(0.3), lineWidth: 1)
        }
        .shadow(color: .green.opacity(0.1), radius: 8, x: 0, y: 2)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    private var permissionInstructionsView: some View {
        VStack(spacing: 12) {
            Text("How to enable microphone access:")
                .font(.subheadline)
                .fontWeight(.medium)
            
            VStack(alignment: .leading, spacing: 8) {
                instructionStep("1.", "Open System Settings")
                instructionStep("2.", "Go to Privacy & Security → Microphone")
                instructionStep("3.", "Find CallAI and toggle it ON")
                instructionStep("4.", "Restart the app")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func instructionStep(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(number)
                .fontWeight(.semibold)
            Text(text)
                .font(.subheadline)
        }
    }
    
    private var permissionActionButtons: some View {
        HStack(spacing: 12) {
            Button("Open System Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 12))
            
            Button("Check Again") {
                Task { @MainActor in
                    audioService.refreshPermissionStatus()
                }
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.roundedRectangle(radius: 12))
            
            Button("FORCE PERMISSION DIALOG") {
                Task { @MainActor in
                    await audioService.forceSystemPermissionDialog()
                    // Refresh status after force request
                    audioService.refreshPermissionStatus()
                }
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 12))
            .foregroundColor(.white)
            .background(.red)
            
            #if DEBUG
            Button("Debug: Force Refresh") {
                Task { @MainActor in
                    print("[DEBUG] Current status: \(audioService.authorizationStatus)")
                    audioService.refreshPermissionStatus()
                    print("[DEBUG] New status: \(audioService.authorizationStatus)")
                }
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.roundedRectangle(radius: 12))
            .foregroundColor(.orange)
            #endif
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.surfaceBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    meetingSidebar
                    mainContentArea
            }
        }
        .navigationTitle("Record Meeting")
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: selectedMeeting != nil)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: checkRecordingPermission())
            .onAppear {
                // Always refresh permission status when view appears
                Task { @MainActor in
                    audioService.refreshPermissionStatus()
                }
                
                // Force permission request on appear - DRASTIC APPROACH
                Task {
                    await audioService.forceSystemPermissionDialog()
                    // Refresh status after request
                    await MainActor.run {
                        audioService.refreshPermissionStatus()
                    }
                }
                
                // Check for pending meeting from another tab
                if let pendingMeeting = meetingSelectionManager.consumePendingMeeting() {
                    selectedMeeting = pendingMeeting
                }
                
                // Start periodic permission checking if permission is denied
                if audioService.authorizationStatus == .denied {
                    startPermissionCheckTimer()
                }
            }
            .onDisappear {
                // Stop the timer when view disappears
                permissionCheckTimer?.invalidate()
                permissionCheckTimer = nil
            }
            .sheet(isPresented: $showingCustomMeeting) {
                CustomMeetingCreationView(
                    title: $customMeetingTitle,
                    date: $customMeetingDate,
                    duration: $customMeetingDuration,
                    isPresented: $showingCustomMeeting
                ) { meeting in
                    selectedMeeting = meeting
                    modelContext.insert(meeting)
                    try? modelContext.save()
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func checkRecordingPermission() -> Bool {
        return audioService.authorizationStatus == .granted
    }
    
    private func startRecording() async {
        guard let meeting = selectedMeeting else { return }
        
        let recordingURL = await audioService.startRecording(for: meeting)
        if let url = recordingURL {
            print("[RecordingView] Recording started successfully at: \(url)")
        } else {
            print("[RecordingView] Recording started but no URL returned")
        }
    }
    
    private func stopRecording() {
        audioService.stopRecording()
    }
    
    private func startPermissionCheckTimer() {
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            Task { @MainActor in
                audioService.refreshPermissionStatus()
                if audioService.authorizationStatus == .granted {
                    permissionCheckTimer?.invalidate()
                    permissionCheckTimer = nil
                }
            }
        }
    }
    
    private func openCalendarApp() {
        let calendarURL = URL(fileURLWithPath: "/System/Applications/Calendar.app")
        NSWorkspace.shared.openApplication(at: calendarURL, 
                                         configuration: NSWorkspace.OpenConfiguration()) { app, error in
            if app == nil || error != nil {
                openCalendarAppFallback()
            }
        }
    }
    
    private func openCalendarAppFallback() {
        let alternativeURL = URL(fileURLWithPath: "/Applications/Calendar.app")
        NSWorkspace.shared.openApplication(at: alternativeURL, 
                                         configuration: NSWorkspace.OpenConfiguration()) { _, _ in
            openCalendarAppByBundleID()
        }
    }
    
    private func openCalendarAppByBundleID() {
        if let bundleURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.iCal") {
            NSWorkspace.shared.openApplication(at: bundleURL, 
                                             configuration: NSWorkspace.OpenConfiguration()) { _, _ in }
        }
    }
}

struct SelectedMeetingView: View {
    let meeting: Meeting
    let onRemove: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Selected Meeting")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                Spacer()
                Button("Change", action: onRemove)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text(meeting.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(meeting.startDate, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(meeting.startDate, style: .time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                    
                    if let location = meeting.location, !location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "location")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            Text(location)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Spacer()
                    }
                }
                
                if !meeting.participants.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(meeting.participants.joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                        Spacer()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.quaternary, lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial.opacity(0.5))
                .blendMode(.overlay)
        )
    }
}

struct SelectMeetingPrompt: View {
    let onCreateMeeting: () -> Void
    let onViewCalendar: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(.blue.gradient)
                    .symbolEffect(.bounce, options: .repeating)
                
                VStack(spacing: 8) {
                    Text("No Meeting Selected")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("Select a meeting from your calendar or create a new one to start recording")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
            }
            
            VStack(spacing: 12) {
                Button(action: onCreateMeeting) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("New Meeting")
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.blue.gradient)
                    )
                }
                .buttonStyle(.plain)
                
                Button(action: onViewCalendar) {
                    HStack {
                        Image(systemName: "calendar")
                        Text("View Calendar")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.blue, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial.opacity(0.5))
                .blendMode(.overlay)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(.quaternary, lineWidth: 1)
        }
    }
}

struct RecordingControlsView: View {
    let isRecording: Bool
    let duration: TimeInterval
    let level: Float
    let canRecord: Bool
    let selectedMeeting: Meeting?
    let startAction: () async -> Void
    let stopAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Recording status
            HStack {
            if isRecording {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(.red)
                            .frame(width: 12, height: 12)
                            .scaleEffect(isRecording ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isRecording)
                        
                        Text("Recording")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.red)
                    }
                } else {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(canRecord ? .green : .gray)
                            .frame(width: 12, height: 12)
                        
                        Text(canRecord ? "Ready to Record" : "Select a Meeting")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(canRecord ? .green : .secondary)
                    }
                }
                
                Spacer()
                
                if isRecording {
                    Text(formatDuration(duration))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                        .monospacedDigit()
                }
            }
            
            // Audio level indicator
            if isRecording {
                AudioLevelView(level: level)
            }
            
            // Record button
            Button(action: {
                if isRecording {
                    stopAction()
                } else {
                        Task {
                            await startAction()
                    }
                }
            }) {
                HStack {
                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.title2)
                    Text(isRecording ? "Stop Recording" : "Start Recording")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isRecording ? Color.red.gradient : (canRecord ? Color.blue.gradient : Color.gray.gradient))
                )
            }
            .buttonStyle(.plain)
            .disabled(!canRecord && !isRecording)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.quaternary, lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct AudioLevelView: View {
    let level: Float
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<20, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor(for: index))
                    .frame(width: 4, height: barHeight(for: index))
                    .animation(.easeInOut(duration: 0.1), value: level)
            }
        }
        .frame(height: 40)
    }
    
    private func barHeight(for index: Int) -> CGFloat {
        let normalizedLevel = CGFloat(level)
        let barIndex = CGFloat(index)
        let threshold = barIndex / 20.0
        
        if normalizedLevel > threshold {
            return 8 + (normalizedLevel - threshold) * 32
        } else {
            return 8
        }
    }
    
    private func barColor(for index: Int) -> Color {
        let normalizedLevel = CGFloat(level)
        let barIndex = CGFloat(index)
        let threshold = barIndex / 20.0
        
        if normalizedLevel > threshold {
            if index < 7 {
                return .green
            } else if index < 14 {
                return .yellow
            } else {
                return .red
            }
        } else {
            return .gray.opacity(0.2)
        }
    }
}

struct ModernPermissionBanner: View {
    let icon: String
    let title: String
    let message: String
    let buttonTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(.orange.gradient)
                    .symbolEffect(.bounce, options: .repeating)
                
                VStack(spacing: 6) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
            }
            
            Button(action: action) {
                    Text(buttonTitle)
                    .font(.headline)
                        .fontWeight(.semibold)
                    .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.orange.gradient)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(.orange.opacity(0.3), lineWidth: 1)
        }
        .shadow(color: .orange.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

struct MeetingSidebar: View {
    @Binding var selectedMeeting: Meeting?
    @Binding var selectedTab: Int
    @StateObject private var calendarService = CalendarService()
    @State private var showingCustomMeeting = false
    @State private var customMeetingTitle = ""
    @State private var customMeetingDate = Date()
    @State private var customMeetingDuration = 60.0
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(spacing: 0) {
            meetingSelectorHeader
            
            Divider()
            
            meetingsList
        }
        .background(Color.secondary.opacity(0.1))
        .onAppear {
            if calendarService.authorizationStatus == .fullAccess {
                Task {
                    await calendarService.loadUpcomingMeetings()
                }
            }
        }
        .sheet(isPresented: $showingCustomMeeting) {
            CustomMeetingCreationView(
                title: $customMeetingTitle,
                date: $customMeetingDate,
                duration: $customMeetingDuration,
                isPresented: $showingCustomMeeting
            ) { meeting in
                selectedMeeting = meeting
                modelContext.insert(meeting)
                try? modelContext.save()
            }
        }
    }
    
    private var meetingSelectorHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Select Meeting")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text("Choose a meeting to record")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                showingCustomMeeting = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var meetingsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if calendarService.meetings.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        
                        Text("No upcoming meetings")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Button("Create Meeting") {
                            showingCustomMeeting = true
                        }
                        .font(.caption)
                        .foregroundStyle(.blue)
                    }
                    .padding(.vertical, 20)
                } else {
                    ForEach(calendarService.meetings, id: \.id) { meeting in
                        MeetingRowView(meeting: meeting, isSelected: selectedMeeting?.id == meeting.id) {
                            selectedMeeting = meeting
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
    }
}

struct MeetingRowView: View {
    let meeting: Meeting
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(meeting.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text(meeting.startDate, style: .time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if let location = meeting.location, !location.isEmpty {
                            Text("•")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text(location)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct CustomMeetingCreationView: View {
    @Binding var title: String
    @Binding var date: Date
    @Binding var duration: Double
    @Binding var isPresented: Bool
    let onSave: (Meeting) -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    Text("Meeting Details")
                        .font(AppFont.h2)
                        .semanticForeground(AppColor.textPrimary)
                    
                    // Title
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Meeting Title")
                            .font(AppFont.bodyEmphasized)
                            .semanticForeground(AppColor.textSecondary)
                        TextField("Enter a title", text: $title)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: AppRadius.sm)
                                    .fill(AppColor.surfaceCard)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppRadius.sm)
                                            .stroke(AppColor.borderHairline, lineWidth: 1)
                                    )
                            )
                            .semanticForeground(AppColor.textPrimary)
                    }
                    
                    // Date & Time
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Date & Time")
                            .font(AppFont.bodyEmphasized)
                            .semanticForeground(AppColor.textSecondary)
                        #if os(macOS)
                        DatePicker("", selection: $date)
                            .labelsHidden()
                        #else
                        DatePicker("Date & Time", selection: $date)
                        #endif
                    }
                    
                    // Duration
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        HStack {
                            Text("Duration")
                                .font(AppFont.bodyEmphasized)
                                .semanticForeground(AppColor.textSecondary)
                            Spacer()
                            Text("\(Int(duration)) min")
                                .font(AppFont.footnote)
                                .semanticForeground(AppColor.textMuted)
                        }
                        Slider(value: $duration, in: 15...240, step: 15)
                    }
                }
                .padding(AppSpacing.xl)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.card)
                        .fill(AppColor.surfaceElevated)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.card)
                                .stroke(AppColor.borderHairline, lineWidth: 1)
                        )
                )
                .padding(AppSpacing.xl)
            }
            .background(AppColor.surfaceBackground.ignoresSafeArea())
            .navigationTitle("New Meeting")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .buttonStyle(.bordered)
                    .font(AppFont.buttonMedium)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createMeeting()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColor.brandPurple)
                    .font(AppFont.buttonLarge)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .frame(minWidth: 560, minHeight: 420)
    }
    
    private func createMeeting() {
        let endDate = date.addingTimeInterval(duration * 60)
        let meeting = Meeting(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            startDate: date,
            endDate: endDate
        )
        onSave(meeting)
        isPresented = false
    }
}

#Preview {
    RecordingView(selectedTab: .constant(1))
        .modelContainer(for: [Meeting.self, Transcript.self])
}
