import SwiftUI
import Foundation

// MARK: - Widget Models
struct Widget: Identifiable, Codable {
    let id: UUID
    var type: WidgetType
    var data: WidgetData
    var position: Int
    
    init(type: WidgetType, data: WidgetData = WidgetData(), position: Int = 0) {
        self.id = UUID()
        self.type = type
        self.data = data
        self.position = position
    }
}

enum WidgetType: String, CaseIterable, Codable {
    case reminders = "Reminders"
    case schedule = "Schedule"
    case childLog = "Child Log"
    case weather = "Weather"
    case notes = "Notes"
    case emergencyContacts = "Emergency"
    
    var icon: String {
        switch self {
        case .reminders: return "bell.fill"
        case .schedule: return "calendar"
        case .childLog: return "heart.text.square.fill"
        case .weather: return "cloud.sun.fill"
        case .notes: return "note.text"
        case .emergencyContacts: return "phone.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .reminders: return Color(red: 1.0, green: 0.8, blue: 0.8) // Light pink
        case .schedule: return Color(red: 0.8, green: 0.9, blue: 1.0) // Light blue
        case .childLog: return Color(red: 0.95, green: 0.95, blue: 0.85) // Light cream
        case .weather: return Color(red: 0.85, green: 0.9, blue: 1.0) // Very light blue
        case .notes: return Color(red: 1.0, green: 0.95, blue: 0.8) // Light yellow
        case .emergencyContacts: return Color(red: 1.0, green: 0.85, blue: 0.85) // Light red
        }
    }
}

struct WidgetData: Codable {
    var items: [String] = []
    var lastUpdated: Date = Date()
    var isEnabled: Bool = true
    var widgetSize: WidgetSize = .large
    
    // Specific data for different widget types
    var temperature: String = ""
    var scheduleItems: [ScheduleItem] = []
    var logEntries: [LogEntry] = []
}

enum WidgetSize: String, CaseIterable, Codable {
    case small = "Small"
    case large = "Large"
}

struct ScheduleItem: Identifiable, Codable {
    let id: UUID
    var time: String
    var activity: String
    var icon: String
    
    init(time: String, activity: String, icon: String) {
        self.id = UUID()
        self.time = time
        self.activity = activity
        self.icon = icon
    }
}

struct LogEntry: Identifiable, Codable {
    let id: UUID
    var category: LogCategory
    var note: String
    var timestamp: Date
    
    init(category: LogCategory, note: String) {
        self.id = UUID()
        self.category = category
        self.note = note
        self.timestamp = Date()
    }
}

enum LogCategory: String, CaseIterable, Codable {
    case food = "Food"
    case sleep = "Sleep"
    case play = "Play"
    case medicine = "Medicine"
    case mood = "Mood"
    
    var icon: String {
        switch self {
        case .food: return "🍎"
        case .sleep: return "🛏️"
        case .play: return "⚽"
        case .medicine: return "💊"
        case .mood: return "😊"
        }
    }
}
