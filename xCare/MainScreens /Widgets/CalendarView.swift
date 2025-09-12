import SwiftUI

struct CalendarView: View {
    @ObservedObject var appData: AppData
    @State private var newEvent = ""

    var body: some View {
        VStack(spacing: 20) {
            TextField("Enter event...", text: $newEvent)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button(action: {
                if !newEvent.isEmpty {
                    appData.calendarEvents.append(newEvent)
                    newEvent = ""
                }
            }) {
                Text("Add Event")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }

            List {
                ForEach(appData.calendarEvents, id: \.self) { event in
                    Text(event)
                }
            }

            Spacer()
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
    }
}

