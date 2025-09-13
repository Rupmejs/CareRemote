import SwiftUI

@main
struct xCareApp: App {
    @StateObject private var appState = AppState() // ✅ session manager

    var body: some Scene {
        WindowGroup {
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

