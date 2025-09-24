import SwiftUI

// MARK: - Widget Views
struct WidgetView: View {
    @Binding var widget: Widget
    let onDelete: () -> Void
    
    var body: some View {
        Group {
            switch widget.type {
            case .childLocation:
                ChildLocationWidget(widget: $widget)
            case .reminders:
                RemindersWidget(widget: $widget)
            case .schedule:
                ScheduleWidget(widget: $widget)
            case .childLog:
                ChildLogWidget(widget: $widget)
            case .weather:
                WeatherWidget(widget: $widget)
            case .notes:
                NotesWidget(widget: $widget)
            case .emergencyContacts:
                EmergencyWidget(widget: $widget)
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Remove Widget", systemImage: "trash")
            }
        }
    }
}

// MARK: - Child Location Widget
struct ChildLocationWidget: View {
    @Binding var widget: Widget
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CHILD'S LOCATION")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black.opacity(0.7))
            
            // Simple path visualization
            ZStack {
                // Path lines
                Path { path in
                    path.move(to: CGPoint(x: 20, y: 40))
                    path.addLine(to: CGPoint(x: 60, y: 20))
                    path.addLine(to: CGPoint(x: 120, y: 35))
                    path.addLine(to: CGPoint(x: 180, y: 15))
                    path.addLine(to: CGPoint(x: 240, y: 30))
                }
                .stroke(Color.blue.opacity(0.6), lineWidth: 3)
                
                // Current location dot
                Circle()
                    .fill(Color.blue)
                    .frame(width: 12, height: 12)
                    .position(x: 120, y: 35)
                
                HStack {
                    Spacer()
                    Button(action: {
                        // Start trip action
                    }) {
                        Text("Start Trip")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(20)
                    }
                }
                .padding(.top, 40)
            }
            .frame(height: 80)
        }
        .padding()
        .background(widget.type.color)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Reminders Widget
struct RemindersWidget: View {
    @Binding var widget: Widget
    @State private var newReminder = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("REMINDERS")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black.opacity(0.7))
                Spacer()
                Button(action: addReminder) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.orange)
                        .font(.title3)
                }
            }
            
            if widget.data.items.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bell")
                        .font(.title2)
                        .foregroundColor(.orange.opacity(0.5))
                    Text("No reminders")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            } else {
                ForEach(widget.data.items.indices, id: \.self) { index in
                    HStack(spacing: 8) {
                        Image(systemName: "🥪")
                            .foregroundColor(.orange)
                        Text(widget.data.items[index])
                            .font(.system(size: 14))
                            .foregroundColor(.black)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(widget.type.color)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
        .onTapGesture {
            // Show add reminder alert
        }
    }
    
    private func addReminder() {
        widget.data.items.append("Lunch 12 PM")
    }
}

// MARK: - Schedule Widget
struct ScheduleWidget: View {
    @Binding var widget: Widget
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SCHEDULE")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black.opacity(0.7))
            
            if widget.data.scheduleItems.isEmpty {
                // Add default schedule items
                let defaultItems = [
                    ScheduleItem(time: "9:00", activity: "", icon: "🎓"),
                    ScheduleItem(time: "3:30", activity: "", icon: "🏀"),
                    ScheduleItem(time: "7:00", activity: "", icon: "🏥")
                ]
                
                ForEach(defaultItems) { item in
                    HStack(spacing: 12) {
                        Text(item.icon)
                            .font(.title3)
                        Text(item.time)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                        Spacer()
                    }
                }
            } else {
                ForEach(widget.data.scheduleItems) { item in
                    HStack(spacing: 12) {
                        Text(item.icon)
                            .font(.title3)
                        Text(item.time)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                        Text(item.activity)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(widget.type.color)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Child Log Widget
struct ChildLogWidget: View {
    @Binding var widget: Widget
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CHILD LOG")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black.opacity(0.7))
            
            // Log category icons
            HStack(spacing: 20) {
                ForEach([("🍎", "Food"), ("🛏️", "Sleep"), ("⚽", "Play")], id: \.0) { emoji, name in
                    VStack(spacing: 4) {
                        Text(emoji)
                            .font(.title2)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.7))
                            .clipShape(Circle())
                        Text(name)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
            }
            
            Text("No recent entries")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .background(widget.type.color)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Weather Widget
struct WeatherWidget: View {
    @Binding var widget: Widget
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "cloud.sun.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("WEATHER")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black.opacity(0.7))
                Spacer()
                Text("72°F")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.blue)
            }
            
            Text("Partly Cloudy")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Text("Perfect day for outdoor play!")
                .font(.caption)
                .foregroundColor(.blue.opacity(0.8))
                .italic()
        }
        .padding()
        .background(widget.type.color)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Notes Widget
struct NotesWidget: View {
    @Binding var widget: Widget
    @State private var noteText = "Leave a note..."
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(.orange)
                    .font(.title3)
                Text("NOTES")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black.opacity(0.7))
                Spacer()
            }
            
            Text(noteText)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .italic()
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(widget.type.color)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
        .onTapGesture {
            // Open note editor
        }
    }
}

// MARK: - Emergency Widget
struct EmergencyWidget: View {
    @Binding var widget: Widget
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "phone.fill")
                    .foregroundColor(.red)
                    .font(.title3)
                Text("EMERGENCY")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black.opacity(0.7))
                Spacer()
                Button(action: {
                    // Call emergency
                }) {
                    Image(systemName: "phone.circle.fill")
                        .foregroundColor(.red)
                        .font(.title2)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Dr. Smith: (555) 123-4567")
                    .font(.caption)
                    .foregroundColor(.black)
                Text("Emergency: 911")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(widget.type.color)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}
