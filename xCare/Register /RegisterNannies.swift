import SwiftUI

struct RegisterNannies: View {
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showPassword: Bool = false
    @State private var navigateToLogin = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.96, green: 0.95, blue: 0.90).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 30) {
                        Spacer().frame(height: 30)

                        Text("Nanny Register")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.3, green: 0.6, blue: 1.0))

                        Text("Please fill in your details to register")
                            .foregroundColor(.black)
                            .font(.system(size: 16))

                        VStack(spacing: 20) {
                            // Username
                            TextField("", text: $username, prompt: Text("Username").foregroundColor(.black.opacity(0.7)))
                                .foregroundColor(.black)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)

                            // Email
                            TextField("", text: $email, prompt: Text("Email").foregroundColor(.black.opacity(0.7)))
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .foregroundColor(.black)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)

                            // Password with show/hide
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

                            // Confirm Password
                            SecureField("", text: $confirmPassword, prompt: Text("Confirm Password").foregroundColor(.black.opacity(0.7)))
                                .foregroundColor(.black)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)

                            // Error
                            if let error = errorMessage {
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.subheadline)
                            }

                            // Sign Up Button
                            Button(action: { signUp() }) {
                                Text("Sign Up")
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(red: 0.3, green: 0.6, blue: 1.0))
                                    .cornerRadius(12)
                            }
                            .padding(.top, 10)

                            // Navigate to login
                            HStack {
                                Text("Already have an account?")
                                    .foregroundColor(.black)
                                NavigationLink(destination: LoginNanny(), isActive: $navigateToLogin) {
                                    Text("Log In")
                                        .foregroundColor(Color(red: 0.3, green: 0.6, blue: 1.0))
                                        .bold()
                                }
                            }
                            .padding(.top, 10)
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
            }
            .navigationBarTitle("", displayMode: .inline)
        }
    }

    private func signUp() {
        guard !username.isEmpty, !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        // Save to UserDefaults
        var savedUsers = UserDefaults.standard.array(forKey: "nannyUsers") as? [[String: String]] ?? []
        let newUser: [String: String] = ["username": username, "email": email, "password": password]
        savedUsers.append(newUser)
        UserDefaults.standard.set(savedUsers, forKey: "nannyUsers")

        errorMessage = nil
        navigateToLogin = true
    }
}

