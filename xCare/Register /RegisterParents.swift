import SwiftUI

struct RegisterParents: View {
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

                        Text("Parent Register")
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

                            // Password
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
                                NavigationLink(destination: LoginParents(), isActive: $navigateToLogin) {
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

    // MARK: - Sign Up
    private func signUp() {
        guard !username.isEmpty, !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address."
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        saveUser(userType: "parent", username: username, email: email, password: password)

        // Save last registered email for autofill
        UserDefaults.standard.set(email, forKey: "lastRegisteredEmail_parent")
        UserDefaults.standard.synchronize()

        errorMessage = nil
        navigateToLogin = true
    }

    // MARK: - Save User
    private func saveUser(userType: String, username: String, email: String, password: String) {
        let user = ["username": username, "email": email, "password": password]
        let key = userType == "parent" ? "parentUsers" : "nannyUsers"

        var existingUsers = UserDefaults.standard.array(forKey: key) as? [[String: String]] ?? []
        existingUsers.append(user)

        UserDefaults.standard.set(existingUsers, forKey: key)
    }

    // MARK: - Email Validation
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
}

