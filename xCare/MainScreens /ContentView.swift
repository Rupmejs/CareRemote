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

// MARK: - Widget Model
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

// MARK: - Widget View
struct WidgetView: View {
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
    @State private var extraWidgets: [WidgetModel] = [] {
        didSet { saveWidgets() }
    }
    @State private var showingActionSheet = false
    @State private var scrollOffset: CGFloat = 0
    @State private var showSplash = true
    @State private var showLabels = true // Controls both icons & labels
    @State private var showIconLabels = true // NEW: Controls fade of text next to icons

    private let sidePadding: CGFloat = 20
    private let widgetSpacing: CGFloat = 15
    private let mapHeight: CGFloat = 200
    private let backgroundColor = Color(red: 0.96, green: 0.95, blue: 0.90)
    @State private var selectedTab = 1

    init() {
        _extraWidgets = State(initialValue: loadWidgets())
    }

    var body: some View {
        ZStack {
            NavigationView {
                TabView(selection: $selectedTab) {
                    NewView() // Replace with your actual NewView.swift
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

            if showSplash {
                SplashView(isActive: $showSplash).zIndex(1)
            }
        }
    }

    var mainContentView: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 20) {
                    GeometryReader { geo -> Color in
                        DispatchQueue.main.async {
                            let offset = geo.frame(in: .global).minY
                            if offset >= 0 {
                                // At top, show everything
                                withAnimation(.easeIn) { showLabels = true }
                            } else {
                                // Scrolled down, hide everything
                                withAnimation(.easeOut) { showLabels = false }
                            }
                            scrollOffset = offset
                        }
                        return Color.clear
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

                            HStack(spacing: widgetSpacing) {
                                WidgetView(widget: WidgetModel(title: "Reminders", items: ["Buy groceries", "Call Alice"], size: .small))
                                    .frame(maxWidth: .infinity)
                                WidgetView(widget: WidgetModel(title: "Calendar", items: ["Meeting 3 PM", "Dentist 10 AM"], size: .small))
                                    .frame(maxWidth: .infinity)
                            }

                            VStack(spacing: widgetSpacing) {
                                ForEach(0..<extraWidgets.count, id: \.self) { i in
                                    let widget = extraWidgets[i]
                                    if widget.size == .large {
                                        WidgetView(widget: widget)
                                            .frame(maxWidth: .infinity)
                                            .contextMenu { Button("Delete") { deleteWidget(widget) } }
                                    } else {
                                        if i + 1 < extraWidgets.count, extraWidgets[i + 1].size == .small {
                                            HStack(spacing: widgetSpacing) {
                                                WidgetView(widget: widget)
                                                    .frame(maxWidth: .infinity)
                                                    .contextMenu { Button("Delete") { deleteWidget(extraWidgets[i]) } }
                                                WidgetView(widget: extraWidgets[i + 1])
                                                    .frame(maxWidth: .infinity)
                                                    .contextMenu { Button("Delete") { deleteWidget(extraWidgets[i + 1]) } }
                                            }
                                        } else {
                                            HStack(spacing: widgetSpacing) {
                                                WidgetView(widget: widget)
                                                    .frame(maxWidth: .infinity)
                                                    .contextMenu { Button("Delete") { deleteWidget(widget) } }
                                                Spacer().frame(maxWidth: .infinity)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    .padding(.horizontal, sidePadding)
                    .onLongPressGesture { showingActionSheet = true }

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

                    NavigationLink(destination: Text("Settings View")) {
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
                .default(Text("Widget 1 (Small)")) { addExtraWidget(size: .small) },
                .default(Text("Widget 2 (Large)")) { addExtraWidget(size: .large) },
                .cancel()
            ])
        }
    }

    // MARK: - Add/Delete Widgets
    private func addExtraWidget(size: WidgetSize) {
        let newWidget = WidgetModel(title: size == .small ? "Widget 1" : "Widget 2", items: [], size: size)
        extraWidgets.append(newWidget)
    }

    private func deleteWidget(_ widget: WidgetModel) {
        if let index = extraWidgets.firstIndex(of: widget) {
            extraWidgets.remove(at: index)
        }
    }

    // MARK: - Persistence
    private func saveWidgets() {
        if let encoded = try? JSONEncoder().encode(extraWidgets) {
            UserDefaults.standard.set(encoded, forKey: "extraWidgets")
        }
    }

    private func loadWidgets() -> [WidgetModel] {
        if let data = UserDefaults.standard.data(forKey: "extraWidgets"),
           let decoded = try? JSONDecoder().decode([WidgetModel].self, from: data) {
            return decoded
        }
        return []
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

