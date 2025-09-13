import SwiftUI

@main
struct xCareApp: App {
    @StateObject private var appState = AppState() // session manager

    var body: some Scene {
        WindowGroup {
            // Use RootView for initial view selection
            if appState.isLoggedIn {
                HomeView()
                    .environmentObject(appState)
            } else {
                ContentView()
                    .environmentObject(appState)
            }
        }
    }
}

