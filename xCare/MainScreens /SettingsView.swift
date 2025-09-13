import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.96, green: 0.95, blue: 0.90).ignoresSafeArea()

                VStack(spacing: 40) {
                    // Title
                    Text("Settings")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(Color.blue)

                    Spacer()

                    // Logout Button
                    Button(action: {
                        appState.logOut()
                    }) {
                        HStack {
                            Image(systemName: "arrow.backward.square")
                                .foregroundColor(.white)
                                .font(.title2)
                            Text("Log Out")
                                .foregroundColor(.white)
                                .bold()
                                .font(.title2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(16)
                        .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 4)
                    }
                    .padding(.horizontal, 30)

                    Spacer()
                }
                .padding(.top, 60)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AppState())
    }
}

