import SwiftUI
import MapKit
import CoreLocation

// MARK: - Child Profile Models
struct ChildProfile: Identifiable, Codable {
    let id: UUID
    var name: String
    var age: Int
    var gender: ChildGender
    var allergies: [String]
    var favoriteActivities: [String]
    var specialNotes: String
    var imageFileName: String?
    
    init(name: String, age: Int, gender: ChildGender) {
        self.id = UUID()
        self.name = name
        self.age = age
        self.gender = gender
        self.allergies = []
        self.favoriteActivities = []
        self.specialNotes = ""
        self.imageFileName = nil
    }
}

enum ChildGender: String, CaseIterable, Codable {
    case boy = "Boy"
    case girl = "Girl"
    
    var color: Color {
        switch self {
        case .boy: return .blue
        case .girl: return .pink
        }
    }
    
    var icon: String {
        switch self {
        case .boy: return "figure.child"
        case .girl: return "figure.child"
        }
    }
    
    var emoji: String {
        switch self {
        case .boy: return "👦"
        case .girl: return "👧"
        }
    }
}

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
        .shadow(color: Color.gray.opacity(0.4), radius: 5, x: 0, y: 2)
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
    
    // Kids Profile System
    @State private var childrenProfiles: [ChildProfile] = []
    @State private var showingKidsManager = false
    @State private var showingChildEditor = false
    @State private var selectedChild: ChildProfile? = nil
    
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
                    loadChildrenProfiles()
                }
            }
            .onChange(of: appState.isLoggedIn) { _, isLoggedIn in
                if isLoggedIn {
                    // User just logged in - load their widgets and kids
                    loadUserSpecificWidgets()
                    loadChildrenProfiles()
                } else {
                    // User logged out - clear widgets and kids
                    userWidgets = []
                    childrenProfiles = []
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
                            // Kids Profile Section (only for parents)
                            if appState.isLoggedIn && isParentUser() {
                                kidsProfileSection
                            }
                            
                            UserTrackingMapView(userLocation: $userLocation)
                                .frame(height: mapHeight)
                                .cornerRadius(12)
                                .shadow(color: Color.gray.opacity(0.4), radius: 5, x: 0, y: 2)
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
        .sheet(isPresented: $showingKidsManager) {
            KidsManagerView(
                children: $childrenProfiles,
                onSave: saveChildrenProfiles
            )
        }
        .sheet(isPresented: $showingChildEditor) {
            if let child = selectedChild {
                ChildEditorView(
                    child: Binding(
                        get: { child },
                        set: { updatedChild in
                            if let index = childrenProfiles.firstIndex(where: { $0.id == child.id }) {
                                childrenProfiles[index] = updatedChild
                                saveChildrenProfiles()
                            }
                        }
                    )
                ) {
                    showingChildEditor = false
                    selectedChild = nil
                }
            }
        }
    }
    
    // MARK: - Kids Profile Section
    private var kidsProfileSection: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.pink)
                    
                    Text("My Kids")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                Button("Manage") {
                    showingKidsManager = true
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
            
            if childrenProfiles.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "figure.2.and.child.holdinghands")
                        .font(.system(size: 24))
                        .foregroundColor(.orange.opacity(0.6))
                    
                    Text("No kids added yet")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Button("Add Your First Child") {
                        showingKidsManager = true
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.orange)
                    .cornerRadius(16)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(childrenProfiles) { child in
                            Button(action: {
                                selectedChild = child
                                showingChildEditor = true
                            }) {
                                VStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        child.gender.color.opacity(0.8),
                                                        child.gender.color.opacity(0.6)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 68, height: 68)
                                            .overlay(
                                                Circle()
                                                    .stroke(
                                                        LinearGradient(
                                                            colors: [
                                                                child.gender.color,
                                                                child.gender.color.opacity(0.7)
                                                            ],
                                                            startPoint: .top,
                                                            endPoint: .bottom
                                                        ),
                                                        lineWidth: 3
                                                    )
                                            )
                                            .shadow(color: child.gender.color.opacity(0.4), radius: 6, x: 0, y: 3)
                                        
                                        if let imageFileName = child.imageFileName,
                                           let uiImage = FileStorageHelpers.loadImageFromDocuments(filename: imageFileName) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 58, height: 58)
                                                .clipShape(Circle())
                                        } else {
                                            Text(child.gender.emoji)
                                                .font(.system(size: 30))
                                        }
                                        
                                        // Age badge - positioned outside the circle
                                        Text("\(child.age)")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(width: 20, height: 20)
                                            .background(child.gender.color)
                                            .clipShape(Circle())
                                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                                            .offset(x: 28, y: -28)
                                    }
                                    
                                    Text(child.name)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.black)
                                        .lineLimit(1)
                                        .padding(.top, 4)
                                }
                                .frame(width: 80) // Fixed width to prevent cutting
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Add new child button
                        Button(action: {
                            showingKidsManager = true
                        }) {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 68, height: 68)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.gray.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [6]))
                                        )
                                    
                                    Image(systemName: "plus")
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundColor(.gray)
                                }
                                
                                Text("Add Child")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.gray)
                                    .padding(.top, 4)
                            }
                            .frame(width: 80) // Fixed width to match other children
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(Color.white.opacity(0.7)) // Match the main container background
        .cornerRadius(16)
        .shadow(color: Color.gray.opacity(0.2), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Unified Widget Section (Same appearance for all users)
    private var unifiedWidgetSection: some View {
        Group {
            // Show widgets if logged in and has widgets, otherwise show add widgets prompt
            if appState.isLoggedIn && !userWidgets.isEmpty {
                // Display user's personalized widgets
                LazyVStack(spacing: widgetSpacing) {
                    ForEach(Array(userWidgets.enumerated()), id: \.element.id) { index, widget in
                        WidgetView(
                            widget: Binding(
                                get: { userWidgets[index] },
                                set: { userWidgets[index] = $0 }
                            ),
                            onDelete: {
                                deleteUserWidget(at: index)
                            },
                            onSave: {
                                saveUserSpecificWidgets()
                            }
                        )
                    }
                }
                
                // Add Widget Button for users with existing widgets
                Button(action: {
                    showingWidgetSelector = true
                }) {
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
                // Show encouraging add widgets message for everyone without widgets
                VStack(spacing: 16) {
                    Text("Customize Your Dashboard")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.gray)
                    
                    Text("Add widgets to track your child's activities, schedule, reminders, and more!")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: {
                        showingWidgetSelector = true
                    }) {
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
                Button(action: {
                    showingWidgetSelector = true
                }) {
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

    // MARK: - Helper Functions
    private func isParentUser() -> Bool {
        let userType = UserDefaults.standard.string(forKey: "loggedInUserType") ?? ""
        return userType == "parent"
    }

    // MARK: - Children Profile Management
    private func loadChildrenProfiles() {
        let currentUserEmail = UserDefaults.standard.string(forKey: "loggedInEmail") ?? ""
        guard !currentUserEmail.isEmpty else { return }
        
        let childrenKey = "children_\(currentUserEmail)"
        if let data = UserDefaults.standard.data(forKey: childrenKey),
           let decoded = try? JSONDecoder().decode([ChildProfile].self, from: data) {
            childrenProfiles = decoded
        }
    }
    
    private func saveChildrenProfiles() {
        let currentUserEmail = UserDefaults.standard.string(forKey: "loggedInEmail") ?? ""
        guard !currentUserEmail.isEmpty else { return }
        
        let childrenKey = "children_\(currentUserEmail)"
        if let encoded = try? JSONEncoder().encode(childrenProfiles) {
            UserDefaults.standard.set(encoded, forKey: childrenKey)
            UserDefaults.standard.synchronize()
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

// MARK: - Kids Manager View
struct KidsManagerView: View {
    @Binding var children: [ChildProfile]
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingAddChild = false
    @State private var newChildName = ""
    @State private var newChildAge = 5
    @State private var newChildGender: ChildGender = .boy
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.96, green: 0.95, blue: 0.90)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text("👨‍👩‍👧‍👦")
                            .font(.system(size: 40))
                        
                        Text("Manage Your Kids")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                        
                        Text("Add and edit your children's profiles for nannies to see")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)
                    
                    // Children List
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(children) { child in
                                childCard(child)
                            }
                            
                            // Add Child Card
                            addChildCard
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                }
            }
        }
        .sheet(isPresented: $showingAddChild) {
            addChildSheet
        }
    }
    
    private func childCard(_ child: ChildProfile) -> some View {
        HStack(spacing: 16) {
            // Child Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                child.gender.color.opacity(0.8),
                                child.gender.color.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        child.gender.color,
                                        child.gender.color.opacity(0.7)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 4
                            )
                    )
                    .shadow(color: child.gender.color.opacity(0.4), radius: 8, x: 0, y: 4)
                
                if let imageFileName = child.imageFileName,
                   let uiImage = FileStorageHelpers.loadImageFromDocuments(filename: imageFileName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 62, height: 62)
                        .clipShape(Circle())
                } else {
                    Text(child.gender.emoji)
                        .font(.system(size: 32))
                }
                
                // Age badge
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("\(child.age)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(child.gender.color)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    }
                }
                .frame(width: 70, height: 70)
            }
            
            // Child Info
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(child.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Text(child.gender.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(child.gender.color)
                        .cornerRadius(8)
                }
                
                if !child.specialNotes.isEmpty {
                    Text(child.specialNotes)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                if !child.allergies.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        
                        Text("Has allergies")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // Edit Button
            Button(action: {
                // Edit functionality would go here
            }) {
                Image(systemName: "pencil")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                    .frame(width: 32, height: 32)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.9))
        .cornerRadius(20)
        .shadow(color: Color.gray.opacity(0.2), radius: 6, x: 0, y: 3)
        .contextMenu {
            Button(role: .destructive) {
                deleteChild(child)
            } label: {
                Label("Delete Child", systemImage: "trash")
            }
        }
    }
    
    private var addChildCard: some View {
        Button(action: {
            showingAddChild = true
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 70, height: 70)
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.4), style: StrokeStyle(lineWidth: 3, dash: [8]))
                        )
                    
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Add New Child")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.gray)
                    
                    Text("Tap to add another child to your profile")
                        .font(.system(size: 14))
                        .foregroundColor(.gray.opacity(0.7))
                }
                
                Spacer()
            }
            .padding(16)
            .background(Color.white.opacity(0.5))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [10]))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var addChildSheet: some View {
        NavigationView {
            ZStack {
                Color(red: 0.96, green: 0.95, blue: 0.90)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Preview Avatar
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        newChildGender.color.opacity(0.8),
                                        newChildGender.color.opacity(0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                newChildGender.color,
                                                newChildGender.color.opacity(0.7)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 4
                                    )
                            )
                            .shadow(color: newChildGender.color.opacity(0.4), radius: 10, x: 0, y: 5)
                        
                        Text(newChildGender.emoji)
                            .font(.system(size: 40))
                        
                        // Age badge
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Text("\(newChildAge)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 28, height: 28)
                                    .background(newChildGender.color)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                            }
                        }
                        .frame(width: 100, height: 100)
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 20) {
                        // Name Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Child's Name")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                            
                            TextField("Enter name", text: $newChildName)
                                .font(.system(size: 18))
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        // Age Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Age")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                            
                            HStack {
                                Button("-") {
                                    if newChildAge > 1 { newChildAge -= 1 }
                                }
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.blue)
                                .frame(width: 44, height: 44)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                                
                                Spacer()
                                
                                Text("\(newChildAge) years old")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.black)
                                
                                Spacer()
                                
                                Button("+") {
                                    if newChildAge < 18 { newChildAge += 1 }
                                }
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.blue)
                                .frame(width: 44, height: 44)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                        }
                        
                        // Gender Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Gender")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                            
                            HStack(spacing: 12) {
                                ForEach(ChildGender.allCases, id: \.self) { gender in
                                    Button(action: {
                                        newChildGender = gender
                                    }) {
                                        HStack(spacing: 8) {
                                            Text(gender.emoji)
                                                .font(.system(size: 20))
                                            Text(gender.rawValue)
                                                .font(.system(size: 16, weight: .medium))
                                        }
                                        .foregroundColor(newChildGender == gender ? .white : gender.color)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(newChildGender == gender ? gender.color : Color.white)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(gender.color.opacity(0.5), lineWidth: 2)
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Add Button
                    Button("Add Child") {
                        addChild()
                    }
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(newChildName.isEmpty ? Color.gray : newChildGender.color)
                    .cornerRadius(16)
                    .disabled(newChildName.isEmpty)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingAddChild = false
                        resetForm()
                    }
                    .foregroundColor(.gray)
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Add Child")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    private func addChild() {
        let newChild = ChildProfile(
            name: newChildName,
            age: newChildAge,
            gender: newChildGender
        )
        
        children.append(newChild)
        onSave()
        showingAddChild = false
        resetForm()
    }
    
    private func deleteChild(_ child: ChildProfile) {
        children.removeAll { $0.id == child.id }
        onSave()
    }
    
    private func resetForm() {
        newChildName = ""
        newChildAge = 5
        newChildGender = .boy
    }
}

// MARK: - Child Editor View
struct ChildEditorView: View {
    @Binding var child: ChildProfile
    let onDismiss: () -> Void
    
    @State private var showingImagePicker = false
    @State private var newAllergy = ""
    @State private var newActivity = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.96, green: 0.95, blue: 0.90)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Child Avatar with edit option
                        VStack(spacing: 16) {
                            Button(action: {
                                showingImagePicker = true
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    child.gender.color.opacity(0.8),
                                                    child.gender.color.opacity(0.6)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 120, height: 120)
                                        .overlay(
                                            Circle()
                                                .stroke(child.gender.color, lineWidth: 4)
                                        )
                                        .shadow(color: child.gender.color.opacity(0.4), radius: 10, x: 0, y: 5)
                                    
                                    if let imageFileName = child.imageFileName,
                                       let uiImage = FileStorageHelpers.loadImageFromDocuments(filename: imageFileName) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 112, height: 112)
                                            .clipShape(Circle())
                                    } else {
                                        VStack(spacing: 4) {
                                            Text(child.gender.emoji)
                                                .font(.system(size: 40))
                                            Text("Tap to add photo")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    
                                    // Camera icon overlay
                                    VStack {
                                        Spacer()
                                        HStack {
                                            Spacer()
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(.white)
                                                .frame(width: 32, height: 32)
                                                .background(child.gender.color)
                                                .clipShape(Circle())
                                                .shadow(radius: 3)
                                        }
                                    }
                                    .frame(width: 120, height: 120)
                                }
                            }
                            
                            Text("\(child.name), \(child.age)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.black)
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: 20) {
                            // Special Notes
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Special Notes")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.black)
                                
                                TextEditor(text: $child.specialNotes)
                                    .frame(height: 80)
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            
                            // Allergies Section
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Allergies")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.black)
                                    
                                    Spacer()
                                    
                                    Button("Add") {
                                        if !newAllergy.isEmpty {
                                            child.allergies.append(newAllergy)
                                            newAllergy = ""
                                        }
                                    }
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.orange)
                                }
                                
                                TextField("Enter allergy", text: $newAllergy)
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                    )
                                
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                                    ForEach(child.allergies, id: \.self) { allergy in
                                        HStack {
                                            Text(allergy)
                                                .font(.system(size: 12))
                                            Button("×") {
                                                child.allergies.removeAll { $0 == allergy }
                                            }
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.red)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.orange.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer().frame(height: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        onDismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                }
                
                ToolbarItem(placement: .principal) {
                    Text("\(child.name)'s Profile")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.blue)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            PhotoPicker(selectionLimit: 1) { images in
                if let image = images.first,
                   let filename = FileStorageHelpers.saveImageToDocuments(image) {
                    child.imageFileName = filename
                }
            }
        }
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
