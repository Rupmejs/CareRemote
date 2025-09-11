import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    // Map-related state
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.334_900, longitude: -122.009_020),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var userLocation: CLLocationCoordinate2D?

    var body: some View {
        NavigationView {
            ZStack {
                // Full-screen beige background
                Color(red: 0.96, green: 0.95, blue: 0.90)
                    .ignoresSafeArea()

                VStack {
                    Spacer()
                        .frame(height: 50) // top spacing

                    // Map widget with button-style filter
                    Map(coordinateRegion: $region, showsUserLocation: true)
                        .frame(height: 200) // slightly smaller
                        .cornerRadius(12)
                        .shadow(color: .gray.opacity(0.4), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )

                    Spacer() // fill remaining space
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("")
            // + button at the top right
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
                // Request location permission and get user location
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

// Simple Location Manager
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

#Preview {
    ContentView()
}

