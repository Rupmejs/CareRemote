import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @State private var showLogoutAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.96, green: 0.95, blue: 0.90)
                    .ignoresSafeArea()

                VStack(spacing: 30) {
                    Text("Settings")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.3, green: 0.6, blue: 1.0))
                        .padding(.top, 40)

                    Spacer()

                    // Logout Button
                    Button(action: {
                        showLogoutAlert = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                                .font(.title2)
                            Text("Log Out")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                        .padding(.horizontal, 20)
                    }
                    .alert(isPresented: $showLogoutAlert) {
                        Alert(
                            title: Text("Log Out"),
                            message: Text("Are you sure you want to log out?"),
                            primaryButton: .destructive(Text("Log Out")) {
                                logout()
                            },
                            secondaryButton: .cancel()
                        )
                    }

                    Spacer()
                }
            }
            .navigationBarTitle("", displayMode: .inline)
        }
    }

    private func logout() {
        // 1. Set appState to logged out
        appState.isLoggedIn = false

        // 2. Clear saved credentials (optional)
        UserDefaults.standard.removeObject(forKey: "parentUser")
        UserDefaults.standard.removeObject(forKey: "nannyUser")

        // 3. Dismiss SettingsView
        presentationMode.wrappedValue.dismiss()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView().environmentObject(AppState())
    }
}

