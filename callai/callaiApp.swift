//
//  callaiApp.swift
//  callai
//
//  Created by Edward Harrison on 9/2/25.
//

import SwiftUI
import SwiftData

@main
struct callaiApp: App {
    let modelContainer: ModelContainer
    
    init() {
        do {
            modelContainer = try ModelContainer(for: Meeting.self, Transcript.self)
        } catch {
            fatalError("Failed to initialize model container: \(error)")
        }
        
        // Initialize API key on app launch
        APIKeyConfig.shared.initializeKeychainIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.automatic)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About CallAI") {
                    NSApplication.shared.orderFrontStandardAboutPanel(options: [
                        .applicationName: "CallAI",
                        .applicationVersion: "1.0",
                        .credits: NSAttributedString(string: "AI-powered meeting recorder and transcriber", attributes: [:])
                    ])
                }
            }
        }
    }
}
