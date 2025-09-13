import SwiftUI

class AppState: ObservableObject {
    @Published var isLoggedIn: Bool

    init() {
        // Check if already logged in
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
    }
}

