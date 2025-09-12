import SwiftUI

class AppData: ObservableObject {
    @Published var reminders: [String] = []
    @Published var calendarEvents: [String] = []
}

