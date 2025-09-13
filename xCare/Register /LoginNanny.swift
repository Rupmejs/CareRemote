import SwiftUI

struct LoginNanny: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var navigateToHome = false
    @State private var navigateToProfileEditor = false
    @State private var errorMessage: String?

    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.96, green: 0.95, blue: 0.90).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 30) {
                        Spacer().frame(height: 50)

                        Text("Nanny Log In")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.3, green: 0.6, blue: 1.0))

                        Text("Please enter your credentials to log in")
                            .foregroundColor(.black)
                            .font(.system(size: 16))

                        VStack(spacing: 20) {
                            // Email
                            TextField("", text: $email, prompt: Text("Email").foregroundColor(.black.opacity(0.7)))
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .foregroundColor(.black)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)

                            // Password with eye toggle
                            ZStack(alignment: .trailing) {
                                if showPassword {
                                    TextField("", text: $password, prompt: Text("Password").foregroundColor(.black.opacity(0.7)))
                                        .foregroundColor(.black)
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(12)
                                } else {
                                    SecureField("", text: $password, prompt: Text("Password").foregroundColor(.black.opacity(0.7)))
                                        .foregroundColor(.black)
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(12)
                                }

                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 12)
                                }
                            }

                            // Error message
                            if let error = errorMessage {
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.subheadline)
                            }

                            // Log In Button
                            Button(action: login) {
                                Text("Log In")
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(red: 0.3, green: 0.6, blue: 1.0))
                                    .cornerRadius(12)
                            }

                            // Navigate to Register
                            HStack {
                                Text("Don't have an account?")
                                    .foregroundColor(.black)
                                NavigationLink(destination: RegisterNannies()) {
                                    Text("Sign Up")
                                        .foregroundColor(Color(red: 0.3, green: 0.6, blue: 1.0))
                                        .bold()
                                }
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(20)
                        .shadow(color: .gray.opacity(0.3), radius: 8, x: 0, y: 4)
                        .padding(.horizontal, 20)

                        Spacer()
                    }
                    .padding(.vertical, 30)
                }

                // Navigate to Home
                NavigationLink(destination: HomeView().environmentObject(appState), isActive: $navigateToHome) {
                    EmptyView()
                }

                // Navigate to Profile Editor
                NavigationLink(destination: ProfileEditorView(userType: "nanny") { saved in
                    if let encoded = try? JSONEncoder().encode(saved) {
                        UserDefaults.standard.set(encoded, forKey: "nanny_profile")
                    }
                    navigateToProfileEditor = false
                    navigateToHome = true
                }, isActive: $navigateToProfileEditor) {
                    EmptyView()
                }
            }
            .navigationBarTitle("", displayMode: .inline)
        }
    }

    private func login() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }

        let savedUsers = UserDefaults.standard.array(forKey: "nannyUsers") as? [[String: String]] ?? []

        if let _ = savedUsers.first(where: { $0["email"] == email && $0["password"] == password }) {
            // Successful login
            errorMessage = nil
            appState.logIn(userType: "nanny")

            // Check if profile exists
            if UserDefaults.standard.data(forKey: "nanny_profile") == nil {
                navigateToProfileEditor = true
            } else {
                navigateToHome = true
            }
        } else {
            errorMessage = "Invalid email or password."
        }
    }
}

