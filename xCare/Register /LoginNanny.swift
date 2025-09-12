import SwiftUI

struct LoginNanny: View {
    @State private var email: String = ""
    @State private var password: String = ""

    init() {
        // Navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor(red: 0.96, green: 0.95, blue: 0.90, alpha: 1) // beige
        appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.95, blue: 0.90).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 30) {
                    Spacer().frame(height: 50)

                    Text("Nanny Log In")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.3, green: 0.6, blue: 1.0))

                    Text("Enter your credentials to log in")
                        .foregroundColor(.black)
                        .font(.system(size: 16))
                        .padding(.top, 5)

                    VStack(spacing: 20) {
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

                        Button(action: {
                            print("Nanny Email: \(email)")
                            print("Password: \(password)")
                        }) {
                            Text("Log In")
                                .foregroundColor(.white)
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(red: 0.3, green: 0.6, blue: 1.0))
                                .cornerRadius(12)
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

struct LoginNanny_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LoginNanny()
        }
    }
}

