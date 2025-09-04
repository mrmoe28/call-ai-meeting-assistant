import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showingSettings = false
    @State private var showingDebugView = false
    @AppStorage("prefersDarkMode") private var prefersDarkMode = true
    
    var body: some View {
        ZStack {
            // Background color
            AppColor.surfaceBackground.ignoresSafeArea()
            
            // Modern Dashboard with custom tab bar
            VStack(spacing: 0) {
                // Content based on selected tab
                Group {
                    switch selectedTab {
                    case 0:
                        MeetingsPageView(selectedTab: $selectedTab)
                    case 1:
                        RecordingView(selectedTab: $selectedTab)
                            .background(AppColor.surfaceBackground)
                    case 2:
                        CalendarView()
                            .background(AppColor.surfaceBackground)
                    case 3:
                        TranscriptsView()
                            .background(AppColor.surfaceBackground)
                    case 4:
                        SettingsView(prefersDarkMode: $prefersDarkMode)
                            .background(AppColor.surfaceBackground)
                    default:
                        MeetingsPageView(selectedTab: $selectedTab)
                    }
                }
                
                // Custom Tab Bar
                CustomTabBar(selectedTab: $selectedTab)
            }
        }
        .preferredColorScheme(prefersDarkMode ? .dark : .light)
        .onAppear {
            checkAPIKeyConfiguration()
            // Initialize permission debug service
            _ = PermissionDebugService.shared
            // Proactively request permissions
            Task {
                await requestInitialPermissions()
            }
        }
        #if DEBUG
        .overlay(alignment: .topTrailing) {
            Button("Debug") {
                showingDebugView = true
            }
            .padding()
            .background(AppColor.surfaceElevated)
            .foregroundColor(AppColor.textSecondary)
            .cornerRadius(8)
            .padding()
        }
        .sheet(isPresented: $showingDebugView) {
            PermissionDebugView()
        }
        #endif
    }
    
    private func checkAPIKeyConfiguration() {
        if !AppConfig.shared.hasValidOpenAIAPIKey {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                selectedTab = 3 // Automatically switch to Settings tab if no API key
            }
        }
    }
    
    private func requestInitialPermissions() async {
        // Request microphone permission proactively
        print("Requesting microphone permission...")
        await PermissionDebugService.shared.testMicrophonePermission()
        
        // Request calendar permission proactively  
        print("Requesting calendar permission...")
        await PermissionDebugService.shared.testCalendarPermission()
        
        print("Permission requests completed successfully")
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Meeting.self, Transcript.self])
        .preferredColorScheme(.dark)
}
