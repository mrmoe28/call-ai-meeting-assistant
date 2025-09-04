import SwiftUI

struct CalendarView: View {
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @State private var showingEventDetail = false
    @State private var selectedEvent: CalendarEvent?
    @State private var showingNewEvent = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.surfaceBackground.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: AppSpacing.sectionSpacing) {
                        // Header with month navigation
                        monthHeaderView
                        
                        // Calendar grid
                        calendarGridView
                        
                        // Today's events section
                        todaysEventsSection
                        
                        // Upcoming events section
                        upcomingEventsSection
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, 100) // Space for tab bar
                }
            }
        }
        .navigationTitle("Calendar")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewEvent = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(AppColor.brandPurple)
                }
            }
        }
        .sheet(isPresented: $showingNewEvent) {
            NewEventView(isPresented: $showingNewEvent)
        }
        .sheet(isPresented: $showingEventDetail) {
            if let event = selectedEvent {
                EventDetailView(event: event, isPresented: $showingEventDetail)
            }
        }
    }
    
    // MARK: - Month Header
    
    private var monthHeaderView: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColor.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(AppColor.surfaceElevated, in: Circle())
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            VStack(spacing: 4) {
                Text(currentMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColor.textPrimary)
                
                Text("\(Calendar.current.component(.day, from: Date())) events today")
                    .font(.caption)
                    .foregroundColor(AppColor.textSecondary)
            }
            
            Spacer()
            
            Button {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColor.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(AppColor.surfaceElevated, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, AppSpacing.md)
    }
    
    // MARK: - Calendar Grid
    
    private var calendarGridView: some View {
        VStack(spacing: 0) {
            // Day headers
            HStack(spacing: 0) {
                ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColor.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                }
            }
            
            // Calendar days
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 1) {
                ForEach(calendarDays, id: \.self) { date in
                    CalendarDayView(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                        isToday: Calendar.current.isDateInToday(date),
                        isCurrentMonth: Calendar.current.isDate(date, equalTo: currentMonth, toGranularity: .month),
                        hasEvents: hasEventsOnDate(date),
                        onTap: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedDate = date
                            }
                        }
                    )
                }
            }
        }
        .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .stroke(AppColor.borderHairline, lineWidth: 1)
        }
    }
    
    // MARK: - Today's Events
    
    private var todaysEventsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Today's Events")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(AppColor.textPrimary)
                
                Spacer()
                
                Text("\(todaysEvents.count) events")
                    .font(.caption)
                    .foregroundColor(AppColor.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColor.surfaceElevated, in: Capsule())
            }
            
            if todaysEvents.isEmpty {
                EmptyStateView(
                    icon: "calendar.badge.plus",
                    title: "No events today",
                    message: "Tap the + button to create your first event"
                )
            } else {
                LazyVStack(spacing: AppSpacing.sm) {
                    ForEach(todaysEvents) { event in
                        EventCardView(event: event) {
                            selectedEvent = event
                            showingEventDetail = true
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Upcoming Events
    
    private var upcomingEventsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Upcoming Events")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(AppColor.textPrimary)
                
                Spacer()
                
                Text("Next 7 days")
                    .font(.caption)
                    .foregroundColor(AppColor.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColor.surfaceElevated, in: Capsule())
            }
            
            if upcomingEvents.isEmpty {
                EmptyStateView(
                    icon: "calendar",
                    title: "No upcoming events",
                    message: "Your schedule is clear for the next week"
                )
            } else {
                LazyVStack(spacing: AppSpacing.sm) {
                    ForEach(upcomingEvents) { event in
                        EventCardView(event: event) {
                            selectedEvent = event
                            showingEventDetail = true
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var calendarDays: [Date] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth
        let startOfCalendar = calendar.dateInterval(of: .weekOfYear, for: startOfMonth)?.start ?? startOfMonth
        
        var days: [Date] = []
        for i in 0..<42 { // 6 weeks * 7 days
            if let date = calendar.date(byAdding: .day, value: i, to: startOfCalendar) {
                days.append(date)
            }
        }
        return days
    }
    
    private var todaysEvents: [CalendarEvent] {
        sampleEvents.filter { event in
            Calendar.current.isDate(event.startDate, inSameDayAs: Date())
        }
    }
    
    private var upcomingEvents: [CalendarEvent] {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        
        return sampleEvents.filter { event in
            event.startDate >= tomorrow && event.startDate <= nextWeek
        }
    }
    
    private func hasEventsOnDate(_ date: Date) -> Bool {
        sampleEvents.contains { event in
            Calendar.current.isDate(event.startDate, inSameDayAs: date)
        }
    }
}

// MARK: - Calendar Day View

struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isCurrentMonth: Bool
    let hasEvents: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 16, weight: isToday ? .bold : .medium))
                    .foregroundColor(textColor)
                
                if hasEvents {
                    Circle()
                        .fill(eventIndicatorColor)
                        .frame(width: 6, height: 6)
                } else {
                    Spacer()
                        .frame(height: 6)
                }
            }
            .frame(height: 60)
            .frame(maxWidth: .infinity)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
    
    private var textColor: Color {
        if !isCurrentMonth {
            return AppColor.textMuted.opacity(0.5)
        } else if isSelected {
            return .white
        } else if isToday {
            return AppColor.brandPurple
        } else {
            return AppColor.textPrimary
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return AppColor.brandPurple
        } else if isToday {
            return AppColor.brandPurple.opacity(0.1)
        } else {
            return .clear
        }
    }
    
    private var eventIndicatorColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return AppColor.brandPurple
        } else {
            return AppColor.textSecondary
        }
    }
}

// MARK: - Event Card View

struct EventCardView: View {
    let event: CalendarEvent
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.md) {
                // Time indicator
                VStack(spacing: 2) {
                    Text(event.startDate.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColor.textPrimary)
                    
                    if event.isAllDay {
                        Text("All Day")
                            .font(.caption2)
                            .foregroundColor(AppColor.textSecondary)
                    } else {
                        Text(event.endDate.formatted(date: .omitted, time: .shortened))
                            .font(.caption2)
                            .foregroundColor(AppColor.textSecondary)
                    }
                }
                .frame(width: 60, alignment: .leading)
                
                // Event details
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColor.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if let location = event.location, !location.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption)
                                .foregroundColor(AppColor.textSecondary)
                            Text(location)
                                .font(.caption)
                                .foregroundColor(AppColor.textSecondary)
                                .lineLimit(1)
                        }
                    }
                    
                    if !event.attendees.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.caption)
                                .foregroundColor(AppColor.textSecondary)
                            Text("\(event.attendees.count) attendees")
                                .font(.caption)
                                .foregroundColor(AppColor.textSecondary)
                        }
                    }
                }
                
                Spacer()
                
                // Status indicator
                Circle()
                    .fill(event.statusColor)
                    .frame(width: 12, height: 12)
            }
            .padding(AppSpacing.md)
            .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.md))
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(AppColor.borderHairline, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(AppColor.textMuted)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColor.textPrimary)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.xl)
        .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .stroke(AppColor.borderHairline, lineWidth: 1)
        }
    }
}

// MARK: - Sample Data Models

struct CalendarEvent: Identifiable {
    let id = UUID()
    let title: String
    let startDate: Date
    let endDate: Date
    let location: String?
    let attendees: [String]
    let isAllDay: Bool
    let status: EventStatus
    
    var statusColor: Color {
        switch status {
        case .confirmed:
            return .green
        case .tentative:
            return .orange
        case .cancelled:
            return .red
        }
    }
}

enum EventStatus {
    case confirmed
    case tentative
    case cancelled
}

// MARK: - Sample Data

private let sampleEvents: [CalendarEvent] = [
    CalendarEvent(
        title: "Team Standup",
        startDate: Calendar.current.date(byAdding: .hour, value: 9, to: Date()) ?? Date(),
        endDate: Calendar.current.date(byAdding: .hour, value: 10, to: Date()) ?? Date(),
        location: "Conference Room A",
        attendees: ["John", "Sarah", "Mike"],
        isAllDay: false,
        status: .confirmed
    ),
    CalendarEvent(
        title: "Client Meeting",
        startDate: Calendar.current.date(byAdding: .hour, value: 14, to: Date()) ?? Date(),
        endDate: Calendar.current.date(byAdding: .hour, value: 15, to: Date()) ?? Date(),
        location: "Zoom",
        attendees: ["Client Team", "John"],
        isAllDay: false,
        status: .confirmed
    ),
    CalendarEvent(
        title: "Project Review",
        startDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()) ?? Date(),
        location: nil,
        attendees: ["Sarah", "Mike"],
        isAllDay: false,
        status: .tentative
    ),
    CalendarEvent(
        title: "Company Retreat",
        startDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date(),
        location: "Mountain Resort",
        attendees: ["All Employees"],
        isAllDay: true,
        status: .confirmed
    )
]

#Preview {
    CalendarView()
        .preferredColorScheme(.dark)
}
