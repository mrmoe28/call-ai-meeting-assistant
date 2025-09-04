import SwiftUI

struct NewEventView: View {
    @Binding var isPresented: Bool
    @State private var title = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600) // 1 hour later
    @State private var location = ""
    @State private var notes = ""
    @State private var isAllDay = false
    @State private var selectedColor = Color.blue
    
    private let eventColors: [Color] = [
        .blue, .green, .orange, .red, .purple, .pink, .yellow, .indigo
    ]
    
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
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(eventColors, id: \.self) { color in
                            Button {
                                selectedColor = color
                            } label: {
                                Circle()
                                    .fill(color)
                                    .frame(width: 40, height: 40)
                                    .overlay {
                                        if selectedColor == color {
                                            Circle()
                                                .stroke(.white, lineWidth: 3)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("New Event")
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
                    Button("Create") {
                        createEvent()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 600)
    }
    
    private func createEvent() {
        // TODO: Implement actual event creation
        print("Creating event: \(title)")
        isPresented = false
    }
}

#Preview {
    NewEventView(isPresented: .constant(true))
        .preferredColorScheme(.dark)
}
