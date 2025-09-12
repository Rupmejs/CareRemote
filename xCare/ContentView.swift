import SwiftUI
import MapKit
import CoreLocation

// MARK: - Location Manager
class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    private let manager = CLLocationManager()
    private var completion: ((CLLocation?) -> Void)?

    func requestLocation(completion: @escaping (CLLocation?) -> Void) {
        self.completion = completion
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        completion?(locations.first)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
        completion?(nil)
    }
}

// MARK: - ContentView
struct ContentView: View {
    @StateObject private var appData = AppData() // shared data

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.334_900, longitude: -122.009_020),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var userLocation: CLLocationCoordinate2D?

    private let mapHeight: CGFloat = 200
    private let widgetHeight: CGFloat = 170 // slightly smaller than map
    private let sidePadding: CGFloat = 20
    private let widgetSpacing: CGFloat = 15

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    Spacer().frame(height: 180) // lower everything more

                    // Map widget
                    Map(coordinateRegion: $region, showsUserLocation: true)
                        .frame(height: mapHeight)
                        .cornerRadius(12)
                        .shadow(color: .gray.opacity(0.4), radius: 5, x: 0, y: 2)
                        .padding(.horizontal, sidePadding)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )

                    // Reminder + Calendar widgets side by side
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
            }
            .background(Color(red: 0.96, green: 0.95, blue: 0.90))
            .ignoresSafeArea()
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: NewView()) {
                        Image(systemName: "plus")
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                }
            }
            .onAppear {
                // Request user location
                LocationManager.shared.requestLocation { location in
                    if let loc = location {
                        region.center = loc.coordinate
                        userLocation = loc.coordinate
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
        .frame(maxWidth: .infinity) // ensure equal width inside HStack
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

