import SwiftUI

struct WidgetSelector: View {
    @Binding var widgets: [Widget]
    @Binding var isPresented: Bool
    @Environment(\.presentationMode) var presentationMode
    
    @State private var hasUserProfile = false
    @State private var showingProfilePrompt = false
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.96, green: 0.95, blue: 0.90)
                    .ignoresSafeArea()
                
                if hasUserProfile {
                    // Show widget selector if user has profile
                    widgetSelectorContent
                } else {
                    // Show registration prompt if no profile
                    registrationPromptContent
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue)
                }
                
                if hasUserProfile {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                    }
                }
            }
            .onAppear {
                checkUserProfile()
            }
        }
    }
    
    // MARK: - Widget Selector Content
    private var widgetSelectorContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Add Widget")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                    
                    Text("Choose widgets to customize your dashboard")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Widget Grid
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(WidgetType.allCases, id: \.self) { widgetType in
                        WidgetOptionCard(
                            widgetType: widgetType,
                            isSelected: widgets.contains { $0.type == widgetType }
                        ) {
                            addWidget(type: widgetType)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer().frame(height: 50)
            }
        }
    }
    
    // MARK: - Registration Prompt Content
    private var registrationPromptContent: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(.blue)
            }
            
            // Title and Message
            VStack(spacing: 16) {
                Text("Profile Required")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
                
                Text("You need to create your profile first to customize your dashboard with widgets.")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // Call to Action
            VStack(spacing: 16) {
                Text("Create your profile to:")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Track your child's activities")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Set up personalized reminders")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Customize your dashboard")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 40)
            
            // Action Button
            Button(action: {
                presentationMode.wrappedValue.dismiss()
                // The HomeView will automatically show profile editor for incomplete profiles
            }) {
                HStack {
                    Image(systemName: "person.crop.circle.badge.plus")
                    Text("Create Profile")
                }
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.3, green: 0.6, blue: 1.0), Color.blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // MARK: - Helper Functions
    private func checkUserProfile() {
        let currentUserEmail = UserDefaults.standard.string(forKey: "loggedInEmail") ?? ""
        let userType = UserDefaults.standard.string(forKey: "loggedInUserType") ?? ""
        
        guard !currentUserEmail.isEmpty, !userType.isEmpty else {
            hasUserProfile = false
            return
        }
        
        // Check if user has a complete profile
        let profileKey = "\(userType)_profile_\(currentUserEmail)"
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            // Check if profile is complete (has name, age, and at least one image)
            hasUserProfile = !profile.name.isEmpty &&
                           profile.age > 0 &&
                           !profile.imageFileNames.isEmpty
        } else {
            hasUserProfile = false
        }
        
        print("🔍 Profile check - Email: \(currentUserEmail), UserType: \(userType), HasProfile: \(hasUserProfile)")
    }
    
    private func addWidget(type: WidgetType) {
        // Double-check profile before adding widget
        guard hasUserProfile else {
            showingProfilePrompt = true
            return
        }
        
        // Check if widget already exists
        if let existingIndex = widgets.firstIndex(where: { $0.type == type }) {
            // Remove existing widget
            widgets.remove(at: existingIndex)
        } else {
            // Add new widget
            let newWidget = Widget(type: type, position: widgets.count)
            widgets.append(newWidget)
        }
        
        // Save immediately when widgets change
        saveUserWidgets()
    }
    
    private func saveUserWidgets() {
        // Get current logged-in user email
        let currentUserEmail = UserDefaults.standard.string(forKey: "loggedInEmail") ?? ""
        guard !currentUserEmail.isEmpty else { return }
        
        let userWidgetKey = "widgets_\(currentUserEmail)"
        if let encoded = try? JSONEncoder().encode(widgets) {
            UserDefaults.standard.set(encoded, forKey: userWidgetKey)
            UserDefaults.standard.synchronize()
            print("💾 Widget selector saved \(widgets.count) widgets for user: \(currentUserEmail)")
        }
    }
}

struct WidgetOptionCard: View {
    let widgetType: WidgetType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(widgetType.color)
                        .frame(width: 60, height: 60)
                        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                    
                    Image(systemName: widgetType.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.black.opacity(0.7))
                    
                    if isSelected {
                        Circle()
                            .stroke(Color.blue, lineWidth: 3)
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                            .background(Color.white, in: Circle())
                            .offset(x: 22, y: -22)
                    }
                }
                
                // Title
                Text(widgetType.rawValue)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.white.opacity(0.9))
            .cornerRadius(20)
            .shadow(color: .gray.opacity(isSelected ? 0.3 : 0.1), radius: isSelected ? 8 : 4, x: 0, y: 2)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
