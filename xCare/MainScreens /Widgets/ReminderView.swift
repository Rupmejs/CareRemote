import SwiftUI

struct ReminderView: View {
    @ObservedObject var appData: AppData
    @State private var newReminder = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Reminders List
            List {
                ForEach(appData.reminders, id: \.self) { reminder in
                    HStack {
                        Image(systemName: "circle")
                            .foregroundColor(.gray)
                        Text(reminder)
                    }
                }
                .onDelete { indexSet in
                    appData.reminders.remove(atOffsets: indexSet)
                }
            }
            .listStyle(InsetGroupedListStyle())
            
            // Add new reminder bar (at bottom)
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
                TextField("New Reminder", text: $newReminder, onCommit: addReminder)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding()
            .background(Color(.systemGray6))
        }
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            EditButton()
        }
    }
    
    private func addReminder() {
        let trimmed = newReminder.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            appData.reminders.append(trimmed)
            newReminder = ""
        }
    }
}

