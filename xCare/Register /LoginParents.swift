import SwiftUI

struct LoginParents: View {
    @State private var email: String = UserDefaults.standard.string(forKey: "lastRegisteredEmail_parent") ?? ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var showHome = false
    @State private var errorMessage: String?

    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.96, green: 0.95, blue: 0.90).ignoresSafeArea()

                VStack(spacing: 30) {
                    Spacer().frame(height: 50)

                    Text("Parent Log In")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.3, green: 0.6, blue: 1.0))

                    Text("Please enter your credentials to log in")
                        .foregroundColor(.black)
                        .font(.system(size: 16))

                    VStack(spacing: 20) {
                        // Email (pre-filled if available, still editable)
                        TextField("", text: $email, prompt: Text("Email").foregroundColor(.black.opacity(0.7)))
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                            .foregroundColor(.black)

                        // Password
                        ZStack(alignment: .trailing) {
                            if showPassword {
                                TextField("", text: $password, prompt: Text("Password").foregroundColor(.black.opacity(0.7)))
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(12)
                                    .foregroundColor(.black)
                            } else {
                                SecureField("", text: $password, prompt: Text("Password").foregroundColor(.black.opacity(0.7)))
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(12)
                                    .foregroundColor(.black)
                            }

                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 12)
                            }
                        }

                        if let error = errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.subheadline)
                        }

                        Button(action: login) {
                            Text("Log In")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(red: 0.3, green: 0.6, blue: 1.0))
                                .cornerRadius(12)
                        }

                        HStack {
                            Text("Don't have an account?")
                                .foregroundColor(.black)
                            NavigationLink(destination: RegisterParents()) {
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

                NavigationLink(destination: HomeView().environmentObject(appState), isActive: $showHome) { EmptyView() }
            }
            .navigationBarTitle("", displayMode: .inline)
        }
    }

    private func login() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }

        let savedUsers = UserDefaults.standard.array(forKey: "parentUsers") as? [[String: String]] ?? []

        if let _ = savedUsers.first(where: { $0["email"] == email && $0["password"] == password }) {
            errorMessage = nil
            appState.logIn(userType: "parent")
            UserDefaults.standard.set(email, forKey: "loggedInEmail")
            showHome = true
        } else {
            errorMessage = "Invalid email or password."
        }
    }
}
