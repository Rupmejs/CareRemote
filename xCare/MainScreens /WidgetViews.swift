import SwiftUI

// MARK: - Widget Views
struct WidgetView: View {
    @Binding var widget: Widget
    let onDelete: () -> Void
    let onSave: () -> Void
    
    var body: some View {
        Group {
            switch widget.type {
            case .reminders:
                RemindersWidget(widget: $widget, onSave: onSave)
            case .schedule:
                ScheduleWidget(widget: $widget, onSave: onSave)
            case .childLog:
                ChildLogWidget(widget: $widget, onSave: onSave)
            case .weather:
                WeatherWidget(widget: $widget, onSave: onSave)
            case .notes:
                NotesWidget(widget: $widget, onSave: onSave)
            case .emergencyContacts:
                EmergencyWidget(widget: $widget, onSave: onSave)
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

// MARK: - Reminders Widget
struct RemindersWidget: View {
    @Binding var widget: Widget
    let onSave: () -> Void
    @State private var newReminder = ""
    @State private var showingAddAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("REMINDERS")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black.opacity(0.7))
                Spacer()
                Button(action: { showingAddAlert = true }) {
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
                    Text("Tap + to add one")
                        .font(.caption2)
                        .foregroundColor(.gray.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            } else {
                ForEach(widget.data.items.indices, id: \.self) { index in
                    HStack(spacing: 8) {
                        Button(action: {
                            markReminderComplete(at: index)
                        }) {
                            Image(systemName: "circle")
                                .foregroundColor(.orange)
                        }
                        Text(widget.data.items[index])
                            .font(.system(size: 14))
                            .foregroundColor(.black)
                        Spacer()
                        Button(action: {
                            deleteReminder(at: index)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray.opacity(0.6))
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding()
        .background(widget.type.color)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
        .alert("Add Reminder", isPresented: $showingAddAlert) {
            TextField("Enter reminder", text: $newReminder)
            Button("Add") {
                if !newReminder.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    widget.data.items.append(newReminder.trimmingCharacters(in: .whitespacesAndNewlines))
                    widget.data.lastUpdated = Date()
                    newReminder = ""
                    onSave()
                }
            }
            Button("Cancel", role: .cancel) {
                newReminder = ""
            }
        } message: {
            Text("What would you like to be reminded about?")
        }
    }
    
    private func markReminderComplete(at index: Int) {
        withAnimation {
            widget.data.items.remove(at: index)
            widget.data.lastUpdated = Date()
            onSave()
        }
    }
    
    private func deleteReminder(at index: Int) {
        withAnimation {
            widget.data.items.remove(at: index)
            widget.data.lastUpdated = Date()
            onSave()
        }
    }
}

// MARK: - Schedule Widget
struct ScheduleWidget: View {
    @Binding var widget: Widget
    let onSave: () -> Void
    @State private var showingScheduleEditor = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("SCHEDULE")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black.opacity(0.7))
                Spacer()
                Button(action: { showingScheduleEditor = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            
            if widget.data.scheduleItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.title2)
                        .foregroundColor(.blue.opacity(0.5))
                    Text("No schedule items")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("Tap + to add events")
                        .font(.caption2)
                        .foregroundColor(.gray.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            } else {
                ForEach(widget.data.scheduleItems.indices, id: \.self) { index in
                    HStack(spacing: 12) {
                        Text(widget.data.scheduleItems[index].icon)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(widget.data.scheduleItems[index].time)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.black)
                            if !widget.data.scheduleItems[index].activity.isEmpty {
                                Text(widget.data.scheduleItems[index].activity)
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                        Spacer()
                        Button(action: {
                            deleteScheduleItem(at: index)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray.opacity(0.6))
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding()
        .background(widget.type.color)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
        .sheet(isPresented: $showingScheduleEditor) {
            ScheduleEditorSheet(widget: $widget, onSave: onSave)
        }
    }
    
    private func deleteScheduleItem(at index: Int) {
        withAnimation {
            widget.data.scheduleItems.remove(at: index)
            widget.data.lastUpdated = Date()
            onSave()
        }
    }
}

// MARK: - Schedule Editor Sheet
struct ScheduleEditorSheet: View {
    @Binding var widget: Widget
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTime = Date()
    @State private var activity = ""
    @State private var selectedIcon = "📅"
    
    private let availableIcons = ["📅", "🎓", "🏀", "🏥", "🍎", "🛏️", "⚽", "🎨", "📚", "🎵", "🏃‍♂️", "🍽️"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Add Schedule Item")
                        .font(.title2.bold())
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Time")
                            .font(.headline)
                        DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .frame(height: 120)
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Activity")
                            .font(.headline)
                        TextField("What's happening?", text: $activity)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Icon")
                            .font(.headline)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6)) {
                            ForEach(availableIcons, id: \.self) { icon in
                                Button(action: { selectedIcon = icon }) {
                                    Text(icon)
                                        .font(.title2)
                                        .padding(8)
                                        .background(selectedIcon == icon ? Color.blue.opacity(0.2) : Color.clear)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                Button("Add to Schedule") {
                    let formatter = DateFormatter()
                    formatter.timeStyle = .short
                    let timeString = formatter.string(from: selectedTime)
                    
                    let newItem = ScheduleItem(
                        time: timeString,
                        activity: activity,
                        icon: selectedIcon
                    )
                    
                    widget.data.scheduleItems.append(newItem)
                    widget.data.lastUpdated = Date()
                    onSave()
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Child Log Widget
struct ChildLogWidget: View {
    @Binding var widget: Widget
    let onSave: () -> Void
    @State private var showingLogEntry = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("CHILD LOG")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black.opacity(0.7))
                Spacer()
                Button(action: { showingLogEntry = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
            }
            
            // Log category icons
            HStack(spacing: 15) {
                ForEach(LogCategory.allCases, id: \.self) { category in
                    Button(action: { quickLog(category: category) }) {
                        VStack(spacing: 4) {
                            Text(category.icon)
                                .font(.title3)
                                .frame(width: 32, height: 32)
                                .background(Color.white.opacity(0.7))
                                .clipShape(Circle())
                            Text(category.rawValue)
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
                Spacer()
            }
            
            // Recent entries
            if widget.data.logEntries.isEmpty {
                Text("No recent entries")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(widget.data.logEntries.suffix(3).reversed(), id: \.id) { entry in
                        HStack(spacing: 8) {
                            Text(entry.category.icon)
                                .font(.caption)
                            Text(entry.note)
                                .font(.caption)
                                .foregroundColor(.black)
                                .lineLimit(1)
                            Spacer()
                            Text(timeAgo(entry.timestamp))
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        .padding()
        .background(widget.type.color)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
        .sheet(isPresented: $showingLogEntry) {
            LogEntrySheet(widget: $widget, onSave: onSave)
        }
    }
    
    private func quickLog(category: LogCategory) {
        let defaultNotes: [LogCategory: String] = [
            .food: "Had a snack",
            .sleep: "Took a nap",
            .play: "Playtime",
            .medicine: "Took medicine",
            .mood: "Happy mood"
        ]
        
        let entry = LogEntry(category: category, note: defaultNotes[category] ?? "Activity logged")
        widget.data.logEntries.append(entry)
        widget.data.lastUpdated = Date()
        onSave()
    }
    
    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "now" }
        if interval < 3600 { return "\(Int(interval/60))m" }
        if interval < 86400 { return "\(Int(interval/3600))h" }
        return "\(Int(interval/86400))d"
    }
}

// MARK: - Log Entry Sheet
struct LogEntrySheet: View {
    @Binding var widget: Widget
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategory: LogCategory = .food
    @State private var note = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Add Log Entry")
                        .font(.title2.bold())
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Category")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3)) {
                            ForEach(LogCategory.allCases, id: \.self) { category in
                                Button(action: { selectedCategory = category }) {
                                    VStack(spacing: 8) {
                                        Text(category.icon)
                                            .font(.title2)
                                        Text(category.rawValue)
                                            .font(.caption)
                                            .foregroundColor(.black)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(selectedCategory == category ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                        TextField("Add details...", text: $note, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...6)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                Button("Add Entry") {
                    let entry = LogEntry(
                        category: selectedCategory,
                        note: note.isEmpty ? selectedCategory.rawValue : note
                    )
                    
                    widget.data.logEntries.append(entry)
                    widget.data.lastUpdated = Date()
                    onSave()
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Weather Widget
struct WeatherWidget: View {
    @Binding var widget: Widget
    let onSave: () -> Void
    
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
    let onSave: () -> Void
    @State private var showingNoteEditor = false
    @State private var currentNote = ""
    
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
                Button(action: {
                    currentNote = widget.data.items.first ?? ""
                    showingNoteEditor = true
                }) {
                    Image(systemName: "pencil")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
            }
            
            if widget.data.items.isEmpty || widget.data.items.first?.isEmpty == true {
                VStack(spacing: 8) {
                    Text("No notes yet")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("Tap pencil to add")
                        .font(.caption2)
                        .foregroundColor(.gray.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            } else {
                Text(widget.data.items.first ?? "")
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                    .lineLimit(4)
            }
        }
        .padding()
        .background(widget.type.color)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
        .sheet(isPresented: $showingNoteEditor) {
            NoteEditorSheet(
                note: $currentNote,
                onSave: { note in
                    widget.data.items = [note]
                    widget.data.lastUpdated = Date()
                    onSave()
                }
            )
        }
    }
}

// MARK: - Note Editor Sheet
struct NoteEditorSheet: View {
    @Binding var note: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Edit Note")
                    .font(.title2.bold())
                    .padding(.horizontal)
                
                TextEditor(text: $note)
                    .font(.body)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                
                Spacer()
                
                Button("Save Note") {
                    onSave(note)
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Emergency Widget
struct EmergencyWidget: View {
    @Binding var widget: Widget
    let onSave: () -> Void
    @State private var showingContactEditor = false
    @State private var doctorName = ""
    @State private var doctorPhone = ""
    
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
                    loadCurrentContacts()
                    showingContactEditor = true
                }) {
                    Image(systemName: "pencil")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                if widget.data.items.count >= 2 {
                    HStack {
                        Text("\(widget.data.items[0]): \(widget.data.items[1])")
                            .font(.caption)
                            .foregroundColor(.black)
                        Spacer()
                        Button(action: { callNumber(widget.data.items[1]) }) {
                            Image(systemName: "phone.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title3)
                        }
                    }
                } else {
                    HStack {
                        Text("Dr. Smith: (555) 123-4567")
                            .font(.caption)
                            .foregroundColor(.black)
                        Spacer()
                        Button(action: { callNumber("(555) 123-4567") }) {
                            Image(systemName: "phone.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title3)
                        }
                    }
                }
                
                HStack {
                    Text("Emergency: 911")
                        .font(.caption)
                        .foregroundColor(.red)
                    Spacer()
                    Button(action: { callNumber("911") }) {
                        Image(systemName: "phone.circle.fill")
                            .foregroundColor(.red)
                            .font(.title2)
                    }
                }
            }
        }
        .padding()
        .background(widget.type.color)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
        .sheet(isPresented: $showingContactEditor) {
            EmergencyContactEditor(
                doctorName: $doctorName,
                doctorPhone: $doctorPhone,
                onSave: { name, phone in
                    widget.data.items = [name, phone]
                    widget.data.lastUpdated = Date()
                    onSave()
                }
            )
        }
    }
    
    private func loadCurrentContacts() {
        if widget.data.items.count >= 2 {
            doctorName = widget.data.items[0]
            doctorPhone = widget.data.items[1]
        } else {
            doctorName = "Dr. Smith"
            doctorPhone = "(555) 123-4567"
        }
    }
    
    private func callNumber(_ number: String) {
        let cleanNumber = number.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "-", with: "")
        
        if let url = URL(string: "tel://\(cleanNumber)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Emergency Contact Editor
struct EmergencyContactEditor: View {
    @Binding var doctorName: String
    @Binding var doctorPhone: String
    let onSave: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Emergency Contacts")
                        .font(.title2.bold())
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Doctor Name")
                            .font(.headline)
                        TextField("Enter doctor's name", text: $doctorName)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Phone Number")
                            .font(.headline)
                        TextField("Enter phone number", text: $doctorPhone)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.phonePad)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                Button("Save Contact") {
                    onSave(doctorName, doctorPhone)
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
