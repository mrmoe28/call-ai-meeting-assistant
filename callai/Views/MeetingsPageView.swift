import SwiftUI
import SwiftData

struct MeetingsPageView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Meeting.startDate, order: .reverse)]) private var meetings: [Meeting]
    @Binding var selectedTab: Int
    @State private var selectedMeeting: Meeting?
    @State private var showingNewMeeting = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.surfaceBackground.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Header section
                        VStack(spacing: 20) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Your Meetings")
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    
                                    Text("\(meetings.count) meetings recorded")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            
                            // New Meeting Button
                            Button {
                                selectedTab = 1 // Navigate to recording tab
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                    Text("Record New Meeting")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(.blue.gradient)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, 20)
                        
                        // Meetings List
                        if meetings.isEmpty {
                            EmptyMeetingsView()
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(meetings, id: \.id) { meeting in
                                    MeetingCardView(meeting: meeting) {
                                        // Navigate to meeting detail or transcripts
                                        selectedTab = 2 // Navigate to transcripts tab
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
            }
            .navigationTitle("")
        }
    }
}

struct MeetingCardView: View {
    let meeting: Meeting
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(meeting.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        Text(meeting.startDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Image(systemName: "waveform")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        if let transcript = meeting.transcript {
                            Text("\(transcript.wordCount) words")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Meeting Stats
                HStack(spacing: 16) {
                    Label {
                        Text(formatDuration(meeting.duration))
                            .font(.caption)
                            .fontWeight(.medium)
                    } icon: {
                        Image(systemName: "clock")
                            .foregroundColor(.orange)
                    }
                    
                    if let transcript = meeting.transcript, transcript.confidence > 0 {
                        Label {
                            Text("\(Int(transcript.confidence * 100))%")
                                .font(.caption)
                                .fontWeight(.medium)
                        } icon: {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(transcript.confidence > 0.8 ? .green : .orange)
                        }
                    }
                    
                    Spacer()
                    
                    if meeting.transcript != nil {
                        Text("Transcribed")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.green.opacity(0.2))
                            .foregroundColor(.green)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.secondary.opacity(0.2), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct EmptyMeetingsView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "mic.circle")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(.blue.gradient)
            
            VStack(spacing: 8) {
                Text("No Meetings Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Start recording your first meeting to see it here")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    MeetingsPageView(selectedTab: .constant(0))
        .modelContainer(for: [Meeting.self, Transcript.self])
}