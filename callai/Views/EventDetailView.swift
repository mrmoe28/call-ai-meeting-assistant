import SwiftUI

struct EventDetailView: View {
    let event: CalendarEvent
    @Binding var isPresented: Bool
    @State private var showingEditView = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        HStack {
                            Circle()
                                .fill(event.statusColor)
                                .frame(width: 12, height: 12)
                            
                            Text(event.status.rawValue.capitalized)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(AppColor.textSecondary)
                            
                            Spacer()
                        }
                        
                        Text(event.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(AppColor.textPrimary)
                            .lineLimit(3)
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.lg)
                    
                    // Event Details Card
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        // Date & Time
                        DetailRowView(
                            icon: "calendar",
                            title: "Date & Time",
                            content: dateTimeText
                        )
                        
                        if let location = event.location, !location.isEmpty {
                            DetailRowView(
                                icon: "location.fill",
                                title: "Location",
                                content: location
                            )
                        }
                        
                        if !event.attendees.isEmpty {
                            DetailRowView(
                                icon: "person.2.fill",
                                title: "Attendees",
                                content: event.attendees.joined(separator: ", ")
                            )
                        }
                        
                        DetailRowView(
                            icon: "clock.fill",
                            title: "Duration",
                            content: durationText
                        )
                    }
                    .padding(AppSpacing.lg)
                    .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.lg))
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.lg)
                            .stroke(AppColor.borderHairline, lineWidth: 1)
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    
                    // Action Buttons
                    VStack(spacing: AppSpacing.md) {
                        Button {
                            // TODO: Implement join meeting functionality
                            print("Joining meeting: \(event.title)")
                        } label: {
                            HStack {
                                Image(systemName: "video.fill")
                                Text("Join Meeting")
                            }
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.md)
                            .background(AppColor.brandPurple, in: RoundedRectangle(cornerRadius: AppRadius.md))
                        }
                        .buttonStyle(.plain)
                        
                        HStack(spacing: AppSpacing.md) {
                            Button {
                                showingEditView = true
                            } label: {
                                HStack {
                                    Image(systemName: "pencil")
                                    Text("Edit")
                                }
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(AppColor.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppSpacing.sm)
                                .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.md))
                                .overlay {
                                    RoundedRectangle(cornerRadius: AppRadius.md)
                                        .stroke(AppColor.borderHairline, lineWidth: 1)
                                }
                            }
                            .buttonStyle(.plain)
                            
                            Button {
                                // TODO: Implement delete functionality
                                print("Deleting event: \(event.title)")
                                isPresented = false
                            } label: {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Delete")
                                }
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppSpacing.sm)
                                .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.md))
                                .overlay {
                                    RoundedRectangle(cornerRadius: AppRadius.md)
                                        .stroke(.red.opacity(0.3), lineWidth: 1)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    
                    Spacer(minLength: AppSpacing.xl)
                }
            }
            .background(AppColor.surfaceBackground)
        }
        .navigationTitle("Event Details")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    isPresented = false
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            EditEventView(event: event, isPresented: $showingEditView)
        }
    }
    
    private var dateTimeText: String {
        if event.isAllDay {
            return event.startDate.formatted(date: .complete, time: .omitted)
        } else {
            let start = event.startDate.formatted(date: .abbreviated, time: .shortened)
            let end = event.endDate.formatted(date: .omitted, time: .shortened)
            return "\(start) - \(end)"
        }
    }
    
    private var durationText: String {
        if event.isAllDay {
            return "All day"
        } else {
            let duration = event.endDate.timeIntervalSince(event.startDate)
            let hours = Int(duration) / 3600
            let minutes = Int(duration) % 3600 / 60
            
            if hours > 0 {
                return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
            } else {
                return "\(minutes)m"
            }
        }
    }
}

// MARK: - Detail Row View

struct DetailRowView: View {
    let icon: String
    let title: String
    let content: String
    
    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColor.brandPurple)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(AppColor.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Text(content)
                    .font(.subheadline)
                    .foregroundColor(AppColor.textPrimary)
                    .lineLimit(nil)
            }
            
            Spacer()
        }
    }
}

// MARK: - Edit Event View

struct EditEventView: View {
    let event: CalendarEvent
    @Binding var isPresented: Bool
    @State private var title: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var location: String
    @State private var notes: String
    @State private var isAllDay: Bool
    
    init(event: CalendarEvent, isPresented: Binding<Bool>) {
        self.event = event
        self._isPresented = isPresented
        self._title = State(initialValue: event.title)
        self._startDate = State(initialValue: event.startDate)
        self._endDate = State(initialValue: event.endDate)
        self._location = State(initialValue: event.location ?? "")
        self._notes = State(initialValue: "")
        self._isAllDay = State(initialValue: event.isAllDay)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Event Details") {
                    TextField("Event Title", text: $title)
                        .textFieldStyle(.roundedBorder)
                    
                    Toggle("All Day", isOn: $isAllDay)
                        .toggleStyle(SwitchToggleStyle(tint: AppColor.brandPurple))
                }
                
                Section("Date & Time") {
                    if isAllDay {
                        DatePicker("Date", selection: $startDate, displayedComponents: .date)
                    } else {
                        DatePicker("Start", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                        DatePicker("End", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
                
                Section("Location") {
                    TextField("Location (optional)", text: $location)
                        .textFieldStyle(.roundedBorder)
                }
                
                Section("Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .navigationTitle("Edit Event")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEvent()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 600)
    }
    
    private func saveEvent() {
        // TODO: Implement actual event saving
        print("Saving event: \(title)")
        isPresented = false
    }
}

// MARK: - Extensions

extension EventStatus {
    var rawValue: String {
        switch self {
        case .confirmed:
            return "confirmed"
        case .tentative:
            return "tentative"
        case .cancelled:
            return "cancelled"
        }
    }
}

#Preview {
    EventDetailView(
        event: CalendarEvent(
            title: "Team Standup",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            location: "Conference Room A",
            attendees: ["John", "Sarah", "Mike"],
            isAllDay: false,
            status: .confirmed
        ),
        isPresented: .constant(true)
    )
    .preferredColorScheme(.dark)
}
