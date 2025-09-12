import SwiftUI

struct RegisterNannies: View {
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Register Nanny")
                .font(.largeTitle)
                .bold()
                .padding(.top, 40)

            TextField("Name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            TextField("Phone", text: $phone)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button(action: {
                // Add your registration logic here
                print("Nanny Registered: \(name), \(email), \(phone)")
            }) {
                Text("Register")
                    .font(.title2)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .navigationTitle("Nanny Registration")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    RegisterNannies()
}

