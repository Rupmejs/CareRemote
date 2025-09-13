import SwiftUI

class AppState: ObservableObject {
    @Published var isLoggedIn: Bool

    init() {
        self.isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
    }

    func logIn(userType: String) {
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        UserDefaults.standard.set(userType, forKey: "loggedInUserType")
        self.isLoggedIn = true
    }

    func logOut() {
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        UserDefaults.standard.removeObject(forKey: "loggedInUserType")
        self.isLoggedIn = false

        // Reset the root view to ContentView
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            window.rootViewController = UIHostingController(rootView: ContentView().environmentObject(self))
            window.makeKeyAndVisible()
        }
    }
}

