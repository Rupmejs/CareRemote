import SwiftUI
import MapKit
import CoreLocation

// MARK: - Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    private let manager = CLLocationManager()
    @Published var userLocation: CLLocationCoordinate2D? = nil

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.first else { return }
        DispatchQueue.main.async {
            self.userLocation = loc.coordinate
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}

// MARK: - MapView
struct UserTrackingMapView: UIViewRepresentable {
    @Binding var userLocation: CLLocationCoordinate2D?

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.showsCompass = true
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        if let loc = userLocation {
            let region = MKCoordinateRegion(center: loc,
                                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            uiView.setRegion(region, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: UserTrackingMapView
        init(_ parent: UserTrackingMapView) {
            self.parent = parent
        }
    }
}

// MARK: - Widget Model (Legacy for backwards compatibility)
struct WidgetModel: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var items: [String]
    var size: WidgetSize

    init(id: UUID = UUID(), title: String, items: [String], size: WidgetSize) {
        self.id = id
        self.title = title
        self.items = items
        self.size = size
    }
}

enum WidgetSize: String, Codable {
    case small
    case large
}

// MARK: - Legacy Widget View
struct LegacyWidgetView: View {
    var widget: WidgetModel
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(widget.title)
                .font(.headline)
                .foregroundColor(.black)
            if widget.items.isEmpty {
                Text("Empty widget")
                    .foregroundColor(.black)
                    .italic()
            } else {
                ForEach(widget.items, id: \.self) { item in
                    Text("• \(item)")
                        .foregroundColor(.black)
                }
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .background(Color.white.opacity(0.7))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.4), radius: 5, x: 0, y: 2)
    }
}

// MARK: - SplashView
struct SplashView: View {
    @Binding var isActive: Bool
    @State private var textShown = ""
    private let fullText = "xCare"
    @State private var scale: CGFloat = 1.2
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            Text(textShown)
                .font(.system(size: 50, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.4, green: 0.8, blue: 1.0))
                .tracking(6)
                .scaleEffect(scale)
                .opacity(opacity)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                .onAppear { animateText() }
        }
        .onTapGesture {
            withAnimation(.easeOut(duration: 0.3)) { isActive = false }
        }
        .transition(.opacity)
    }

    private func animateText() {
        textShown = ""
        scale = 1.2
        opacity = 0

        for (index, char) in fullText.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.2) {
                textShown.append(char)
                withAnimation(.easeIn(duration: 0.2)) { scale = 1.0; opacity = 1.0 }

                if textShown.count == fullText.count {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeInOut(duration: 0.5)) { scale = 1.5; opacity = 0 }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isActive = false }
                    }
                }
            }
        }
    }
}

// MARK: - ContentView
struct ContentView: View {
    @ObservedObject private var locationManager = LocationManager.shared
    @State private var userLocation: CLLocationCoordinate2D?
    
    // Legacy widgets (for non-logged-in users)
    @State private var extraWidgets: [WidgetModel] = [] {
        didSet { saveLegacyWidgets() }
    }
    
    // New widget system (for logged-in users)
    @State private var userWidgets: [Widget] = []
    @State private var showingWidgetSelector = false
    @State private var currentUserEmail: String = ""
    
    @State private var showingActionSheet = false
    @State private var scrollOffset: CGFloat = 0
    @State private var showSplash = true
    @State private var showLabels = true
    @State private var showIconLabels = true
    @State private var selectedTab = 1
    
    private let sidePadding: CGFloat = 20
    private let widgetSpacing: CGFloat = 15
    private let mapHeight: CGFloat = 200
    private let backgroundColor = Color(red: 0.96, green: 0.95, blue: 0.90)
    
    @EnvironmentObject var appState: AppState

    init() {
        _extraWidgets = State(initialValue: loadLegacyWidgets())
    }

    var body: some View {
        ZStack {
            NavigationView {
                TabView(selection: $selectedTab) {
                    NewView()
                        .tag(0)
                    mainContentView
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .background(backgroundColor.ignoresSafeArea())
                .edgesIgnoringSafeArea(.all)
                .navigationBarHidden(true)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .blur(radius: showSplash ? 10 : 0)
            .animation(.easeInOut(duration: 0.3), value: showSplash)
            .onAppear {
                if appState.isLoggedIn {
                    loadUserSpecificWidgets()
                }
            }
            .onChange(of: appState.isLoggedIn) { _, isLoggedIn in
                if isLoggedIn {
                    // User just logged in - load their widgets
                    loadUserSpecificWidgets()
                } else {
                    // User logged out - clear widgets
                    userWidgets = []
                    currentUserEmail = ""
                }
            }

            if showSplash {
                SplashView(isActive: $showSplash).zIndex(1)
            }
        }
    }

    var mainContentView: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 20) {
                    GeometryReader { geo in
                        Color.clear
                            .onAppear {
                                let offset = geo.frame(in: .global).minY
                                if offset >= 0 {
                                    withAnimation(.easeIn) { showLabels = true }
                                } else {
                                    withAnimation(.easeOut) { showLabels = false }
                                }
                                scrollOffset = offset
                            }
                            .onChange(of: geo.frame(in: .global).minY) { _, offset in
                                if offset >= 0 {
                                    withAnimation(.easeIn) { showLabels = true }
                                } else {
                                    withAnimation(.easeOut) { showLabels = false }
                                }
                                scrollOffset = offset
                            }
                    }
                    .frame(height: 0)

                    Spacer().frame(height: 150)

                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.7))
                            .shadow(radius: 6)

                        VStack(spacing: widgetSpacing) {
                            UserTrackingMapView(userLocation: $userLocation)
                                .frame(height: mapHeight)
                                .cornerRadius(12)
                                .shadow(color: .gray.opacity(0.4), radius: 5, x: 0, y: 2)
                                .frame(maxWidth: .infinity)

                            // Always show unified widget section
                            unifiedWidgetSection
                            
                            // Show legacy widgets for non-logged users if they have any
                            if !appState.isLoggedIn {
                                defaultWidgetLayout
                            }
                        }
                        .padding()
                    }
                    .padding(.horizontal, sidePadding)
                    .onLongPressGesture {
                        if !appState.isLoggedIn {
                            showingActionSheet = true
                        }
                    }

                    Spacer()
                }
                .padding(.vertical, 20)
            }

            // Top icons with labels and fade-out after 2 seconds
            if showLabels {
                HStack {
                    NavigationLink(destination: Text("Subscription View")) {
                        HStack(spacing: 5) {
                            Image(systemName: "face.smiling")
                                .font(.title)
                                .foregroundColor(.pink)
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                                .shadow(radius: 3)
                            if showIconLabels {
                                Text("Subscription")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.pink.opacity(0.8))
                                    .clipShape(Capsule())
                                    .transition(.opacity)
                            }
                        }
                    }

                    Spacer()

                    NavigationLink(destination: SettingsView().environmentObject(appState)) {
                        HStack(spacing: 5) {
                            if showIconLabels {
                                Text("Settings")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.8))
                                    .clipShape(Capsule())
                                    .transition(.opacity)
                            }
                            Image(systemName: "gear")
                                .font(.title)
                                .foregroundColor(.blue)
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }
                    }
                }
                .padding()
                .transition(.opacity)
                .onAppear {
                    showIconLabels = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation(.easeOut(duration: 0.5)) {
                            showIconLabels = false
                        }
                    }
                }
            }
        }
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(title: Text("Add Widget"), message: Text("Select widget size"), buttons: [
                .default(Text("Widget 1 (Small)")) { addLegacyWidget(size: .small) },
                .default(Text("Widget 2 (Large)")) { addLegacyWidget(size: .large) },
                .cancel()
            ])
        }
        .sheet(isPresented: $showingWidgetSelector) {
            if appState.isLoggedIn {
                WidgetSelector(widgets: $userWidgets, isPresented: $showingWidgetSelector)
                    .onDisappear {
                        saveUserSpecificWidgets()
                    }
            } else {
                LoginPromptView()
            }
        }
    }
    
    // MARK: - Unified Widget Section with Size Support
    private var unifiedWidgetSection: some View {
        Group {
            if appState.isLoggedIn && !userWidgets.isEmpty {
                LazyVStack(spacing: widgetSpacing) {
                    var processedIndices = Set<Int>()
                    
                    ForEach(Array(userWidgets.enumerated()), id: \.element.id) { index, widget in
                        if !processedIndices.contains(index) {
                            if widget.data.widgetSize == .small {
                                // Look for next small widget to pair with
                                if index + 1 < userWidgets.count &&
                                   userWidgets[index + 1].data.widgetSize == .small &&
                                   !processedIndices.contains(index + 1) {
                                    // Two small widgets side by side
                                    HStack(spacing: 10) {
                                        WidgetView(
                                            widget: Binding(
                                                get: { userWidgets[index] },
                                                set: { userWidgets[index] = $0 }
                                            ),
                                            onDelete: { deleteUserWidget(at: index) },
                                            onSave: { saveUserSpecificWidgets() }
                                        )
                                        .frame(maxWidth: .infinity)
                                        
                                        WidgetView(
                                            widget: Binding(
                                                get: { userWidgets[index + 1] },
                                                set: { userWidgets[index + 1] = $0 }
                                            ),
                                            onDelete: { deleteUserWidget(at: index + 1) },
                                            onSave: { saveUserSpecificWidgets() }
                                        )
                                        .frame(maxWidth: .infinity)
                                    }
                                    .onAppear {
                                        processedIndices.insert(index)
                                        processedIndices.insert(index + 1)
                                    }
                                } else {
                                    // Single small widget
                                    HStack(spacing: 10) {
                                        WidgetView(
                                            widget: Binding(
                                                get: { userWidgets[index] },
                                                set: { userWidgets[index] = $0 }
                                            ),
                                            onDelete: { deleteUserWidget(at: index) },
                                            onSave: { saveUserSpecificWidgets() }
                                        )
                                        .frame(maxWidth: .infinity)
                                        
                                        Spacer()
                                            .frame(maxWidth: .infinity)
                                    }
                                    .onAppear {
                                        processedIndices.insert(index)
                                    }
                                }
                            } else {
                                // Large widget (full width)
                                WidgetView(
                                    widget: Binding(
                                        get: { userWidgets[index] },
                                        set: { userWidgets[index] = $0 }
                                    ),
                                    onDelete: { deleteUserWidget(at: index) },
                                    onSave: { saveUserSpecificWidgets() }
                                )
                                .onAppear {
                                    processedIndices.insert(index)
                                }
                            }
                        }
                    }
                }
                
                // Add Widget Button
                Button(action: { showingWidgetSelector = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                        Text("Add Widget")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(20)
                    .shadow(color: .blue.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .padding(.top, 8)
            } else {
                // Show encouraging add widgets message
                VStack(spacing: 16) {
                    Text("Customize Your Dashboard")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.gray)
                    
                    Text("Add widgets to track your child's activities, schedule, reminders, and more!")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: { showingWidgetSelector = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Widget")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(20)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
    }
    
    // MARK: - Default Widget Layout (Only for non-logged users with legacy widgets)
    private var defaultWidgetLayout: some View {
        Group {
            // Only show extra legacy widgets for non-logged users (old functionality)
            if !appState.isLoggedIn && !extraWidgets.isEmpty {
                VStack(spacing: widgetSpacing) {
                    ForEach(0..<extraWidgets.count, id: \.self) { i in
                        let widget = extraWidgets[i]
                        if widget.size == .large {
                            LegacyWidgetView(widget: widget)
                                .frame(maxWidth: .infinity)
                                .contextMenu { Button("Delete") { deleteLegacyWidget(widget) } }
                        } else {
                            if i + 1 < extraWidgets.count, extraWidgets[i + 1].size == .small {
                                HStack(spacing: widgetSpacing) {
                                    LegacyWidgetView(widget: widget)
                                        .frame(maxWidth: .infinity)
                                        .contextMenu { Button("Delete") { deleteLegacyWidget(extraWidgets[i]) } }
                                    LegacyWidgetView(widget: extraWidgets[i + 1])
                                        .frame(maxWidth: .infinity)
                                        .contextMenu { Button("Delete") { deleteLegacyWidget(extraWidgets[i + 1]) } }
                                }
                            } else {
                                HStack(spacing: widgetSpacing) {
                                    LegacyWidgetView(widget: widget)
                                        .frame(maxWidth: .infinity)
                                        .contextMenu { Button("Delete") { deleteLegacyWidget(widget) } }
                                    Spacer().frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                }
                
                // Add Widget button for non-logged users only if they have legacy widgets
                Button(action: { showingWidgetSelector = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                        Text("Add Widget")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(20)
                    .shadow(color: .blue.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .padding(.top, 8)
            }
        }
    }

    // MARK: - User-Specific Widget Management
    private func loadUserSpecificWidgets() {
        // Always get the most current logged-in email
        currentUserEmail = UserDefaults.standard.string(forKey: "loggedInEmail") ?? ""
        guard !currentUserEmail.isEmpty else {
            print("❌ No logged-in email found")
            return
        }
        
        let userWidgetKey = "widgets_\(currentUserEmail)"
        if let data = UserDefaults.standard.data(forKey: userWidgetKey),
           let decoded = try? JSONDecoder().decode([Widget].self, from: data) {
            DispatchQueue.main.async {
                self.userWidgets = decoded
            }
        } else {
            DispatchQueue.main.async {
                self.userWidgets = []
            }
        }
        
        print("✅ Loaded \(userWidgets.count) widgets for user: \(currentUserEmail)")
    }
    
    private func saveUserSpecificWidgets() {
        // Make sure we have current user email
        if currentUserEmail.isEmpty {
            currentUserEmail = UserDefaults.standard.string(forKey: "loggedInEmail") ?? ""
        }
        
        guard !currentUserEmail.isEmpty else {
            print("❌ Cannot save widgets: no logged-in email")
            return
        }
        
        let userWidgetKey = "widgets_\(currentUserEmail)"
        if let encoded = try? JSONEncoder().encode(userWidgets) {
            UserDefaults.standard.set(encoded, forKey: userWidgetKey)
            UserDefaults.standard.synchronize()
            print("💾 Saved \(userWidgets.count) widgets for user: \(currentUserEmail)")
        }
    }
    
    private func deleteUserWidget(at index: Int) {
        withAnimation(.spring()) {
            userWidgets.remove(at: index)
            saveUserSpecificWidgets()
        }
    }

    // MARK: - Legacy Widget Management (Non-logged-in users)
    private func addLegacyWidget(size: WidgetSize) {
        let newWidget = WidgetModel(title: size == .small ? "Widget 1" : "Widget 2", items: [], size: size)
        extraWidgets.append(newWidget)
    }

    private func deleteLegacyWidget(_ widget: WidgetModel) {
        if let index = extraWidgets.firstIndex(of: widget) {
            extraWidgets.remove(at: index)
        }
    }

    private func saveLegacyWidgets() {
        if let encoded = try? JSONEncoder().encode(extraWidgets) {
            UserDefaults.standard.set(encoded, forKey: "extraWidgets")
        }
    }

    private func loadLegacyWidgets() -> [WidgetModel] {
        if let data = UserDefaults.standard.data(forKey: "extraWidgets"),
           let decoded = try? JSONDecoder().decode([WidgetModel].self, from: data) {
            return decoded
        }
        return []
    }
}

// MARK: - Login Prompt View
struct LoginPromptView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.96, green: 0.95, blue: 0.90)
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 50, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    
                    // Title and Message
                    VStack(spacing: 16) {
                        Text("Login Required")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                        
                        Text("Please log in to customize your dashboard with widgets and access personalized features.")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    // Benefits
                    VStack(spacing: 16) {
                        Text("With an account you can:")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Customize your dashboard")
                                    .font(.system(size: 15))
                                    .foregroundColor(.gray)
                            }
                            
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
                                Text("Set personalized reminders")
                                    .font(.system(size: 15))
                                    .foregroundColor(.gray)
                            }
                            
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Connect with caregivers")
                                    .font(.system(size: 15))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        NavigationLink(destination: NewView()) {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                Text("Sign Up")
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
                        
                        Button("Cancel") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppState())
    }
}
