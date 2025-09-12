import SwiftUI

struct RegisterNannies: View {
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var registrationMessage: String = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button(action: registerNanny) {
                    Text("Register")
                        .font(.title2)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                
                if !registrationMessage.isEmpty {
                    Text(registrationMessage)
                        .foregroundColor(.green)
                        .padding(.top, 10)
                }

                Spacer()
            }
            .navigationTitle("Nanny Registration")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    func registerNanny() {
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            registrationMessage = "Please fill in all fields."
            return
        }
        
        // Format registration data
        let entry = "Name: \(name), Email: \(email), Password: \(password)\n"
        
        // Get path to documents folder
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent("RegisteredNannies.txt")
            
            // Append to file
            if FileManager.default.fileExists(atPath: fileURL.path) {
                if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                    fileHandle.seekToEndOfFile()
                    if let data = entry.data(using: .utf8) {
                        fileHandle.write(data)
                        fileHandle.closeFile()
                    }
                }
            } else {
                // File doesn't exist yet, create it
                try? entry.write(to: fileURL, atomically: true, encoding: .utf8)
            }
            
            registrationMessage = "Nanny Registered Successfully!"
        }
        
        // Clear input fields
        name = ""
        email = ""
        password = ""
    }
}

#Preview {
    RegisterNannies()
}

