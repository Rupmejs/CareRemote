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

// MARK: - UIViewRepresentable for MKMapView
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

// MARK: - Scroll Offset PreferenceKey
struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - ContentView
struct ContentView: View {
    @StateObject private var appData = AppData()
    @ObservedObject private var locationManager = LocationManager.shared
    @State private var userLocation: CLLocationCoordinate2D?
    @State private var scrollOffset: CGFloat = 0

    private let mapHeight: CGFloat = 200
    private let widgetHeight: CGFloat = 170
    private let sidePadding: CGFloat = 20
    private let widgetSpacing: CGFloat = 15
    private let navBarHeight: CGFloat = 44
    private let backgroundColor = Color(red: 0.96, green: 0.95, blue: 0.90)

    var navBarOpacity: Double {
        let offset = min(max(-scrollOffset / 100, 0), 1)
        return Double(offset)
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                ScrollView {
                    GeometryReader { geo in
                        Color.clear
                            .preference(key: ScrollOffsetKey.self, value: geo.frame(in: .global).minY)
                    }
                    .frame(height: 0)

                    VStack(spacing: 25) {
                        Spacer().frame(height: 180)

                        // Map
                        UserTrackingMapView(userLocation: $userLocation)
                            .frame(height: mapHeight)
                            .cornerRadius(12)
                            .shadow(color: .gray.opacity(0.4), radius: 5, x: 0, y: 2)
                            .padding(.horizontal, sidePadding)
                            .onReceive(locationManager.$userLocation) { loc in
                                userLocation = loc
                            }

                        // Reminder + Calendar widgets
                        HStack(spacing: widgetSpacing) {
                            NavigationLink(destination: ReminderView(appData: appData)) {
                                WidgetView(title: "Reminders", items: appData.reminders, placeholder: "No reminders yet")
                                    .frame(height: widgetHeight)
                            }
                            .buttonStyle(PlainButtonStyle())

                            NavigationLink(destination: CalendarView(appData: appData)) {
                                WidgetView(title: "Calendar", items: appData.calendarEvents, placeholder: "No events yet")
                                    .frame(height: widgetHeight)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, sidePadding)
                    }
                    .padding(.bottom, 50)
                }
                .background(backgroundColor)
                .ignoresSafeArea()
                .onPreferenceChange(ScrollOffsetKey.self) { value in
                    scrollOffset = value
                }

                // Fading navigation bar overlay
                Color(red: 0.96, green: 0.95, blue: 0.90)
                    .opacity(navBarOpacity)
                    .frame(height: navBarHeight)
                    .ignoresSafeArea(edges: .top)
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: NewView()) {
                        Image(systemName: "plus")
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
}

// MARK: - WidgetView
struct WidgetView: View {
    let title: String
    let items: [String]
    let placeholder: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(title).font(.headline).padding(.bottom, 5)
            if items.isEmpty {
                Text(placeholder).foregroundColor(.gray).italic()
            } else {
                ForEach(items, id: \.self) { item in
                    Text("• \(item)")
                }
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.4), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

