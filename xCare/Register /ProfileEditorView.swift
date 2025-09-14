import SwiftUI

struct ProfileEditorView: View {
    @Environment(\.presentationMode) var presentationMode

    @State private var name: String = ""
    @State private var age: String = ""
    @State private var descriptionText: String = ""
    @State private var uiImages: [UIImage] = []
    @State private var showingPicker = false
    @State private var errorMessage: String?

    let userType: String
    let email: String
    let onSaved: (UserProfile) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.96, green: 0.95, blue: 0.90).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        Text("Create Your Profile")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.3, green: 0.6, blue: 1.0))
                            .padding(.top, 40)

                        // Photos
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Photos")
                                .font(.headline)
                                .foregroundColor(.black)
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(Array(uiImages.enumerated()), id: \.offset) { _, img in
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 120, height: 120)
                                            .clipped()
                                            .cornerRadius(14)
                                            .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
                                    }

                                    Button(action: { showingPicker = true }) {
                                        VStack {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 40))
                                                .foregroundColor(.blue)
                                            Text("Add")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        .frame(width: 120, height: 120)
                                        .background(Color.white)
                                        .cornerRadius(14)
                                        .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }

                        // Info Section
                        VStack(spacing: 16) {
                            TextField("", text: $name, prompt: Text("Full Name").foregroundColor(.black.opacity(0.6)))
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .foregroundColor(.black)

                            TextField("", text: $age, prompt: Text("Age").foregroundColor(.black.opacity(0.6)))
                                .keyboardType(.numberPad)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .foregroundColor(.black)

                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $descriptionText)
                                    .frame(height: 140)
                                    .padding(10)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .foregroundColor(.black)
                                    .scrollContentBackground(.hidden)

                                if descriptionText.isEmpty {
                                    Text("Description")
                                        .foregroundColor(.black.opacity(0.5))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                }
                            }
                        }
                        .padding(.horizontal)

                        if let error = errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.subheadline)
                                .padding(.horizontal)
                        }

                        Button(action: saveProfile) {
                            Text("Save & Continue")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(red: 0.3, green: 0.6, blue: 1.0))
                                .cornerRadius(16)
                                .shadow(color: .gray.opacity(0.4), radius: 6, x: 0, y: 4)
                                .padding(.horizontal, 24)
                        }
                        .padding(.top, 10)
                    }
                    .padding(.bottom, 50)
                }
                .scrollContentBackground(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingPicker) {
                PhotoPicker(selectionLimit: 6) { images in
                    uiImages.append(contentsOf: images)
                }
            }
        }
    }

    private func saveProfile() {
        guard !uiImages.isEmpty else {
            errorMessage = "Please add at least one photo."
            return
        }
        guard let ageInt = Int(age), ageInt > 0 else {
            errorMessage = "Please enter a valid age."
            return
        }
        guard !name.isEmpty else {
            errorMessage = "Please enter your name."
            return
        }
        guard !descriptionText.isEmpty else {
            errorMessage = "Please add a description."
            return
        }

        // Save images
        var filenames: [String] = []
        for img in uiImages {
            if let saved = FileStorageHelpers.saveImageToDocuments(img) {
                filenames.append(saved)
            }
        }

        let profile = UserProfile(
            userType: userType,
            email: email,
            name: name,
            age: ageInt,
            description: descriptionText,
            imageFileNames: filenames
        )

        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: "\(userType)_profile_\(email)")
        }

        onSaved(profile)
        presentationMode.wrappedValue.dismiss()
    }
}

