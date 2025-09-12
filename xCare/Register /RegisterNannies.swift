import SwiftUI

struct RegisterNannies: View {
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""

    var body: some View {
        NavigationView { // Wrap everything in NavigationView
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
                            TextField("", text: $username, prompt: Text("Username").foregroundColor(.black.opacity(0.7)))
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)

                            TextField("", text: $email, prompt: Text("Email").foregroundColor(.black.opacity(0.7)))
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)

                            SecureField("", text: $password, prompt: Text("Password").foregroundColor(.black.opacity(0.7)))
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)

                            SecureField("", text: $confirmPassword, prompt: Text("Confirm Password").foregroundColor(.black.opacity(0.7)))
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)

                            Button(action: {
                                print("Sign Up tapped")
                            }) {
                                Text("Sign Up")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(red: 0.3, green: 0.6, blue: 1.0))
                                    .cornerRadius(12)
                            }

                            HStack {
                                Text("Already have an account?")
                                    .foregroundColor(.black)
                                NavigationLink(destination: LoginNanny()) {
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
}

struct RegisterNannies_Previews: PreviewProvider {
    static var previews: some View {
        RegisterNannies()
    }
}

