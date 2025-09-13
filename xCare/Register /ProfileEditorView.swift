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
    let onSaved: (UserProfile) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.96, green: 0.95, blue: 0.90).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        Text("Create Your Profile")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.3, green: 0.6, blue: 1.0))
                            .padding(.top, 40)

                        // Photos
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(uiImages.enumerated()), id: \.offset) { _, img in
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipped()
                                        .cornerRadius(12)
                                }

                                Button(action: { showingPicker = true }) {
                                    VStack {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 36))
                                            .foregroundColor(.blue)
                                        Text("Add Photos")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .frame(width: 120, height: 120)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .shadow(radius: 2)
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Name
                        TextField("Full name", text: $name)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .foregroundColor(.black)
                            .padding(.horizontal)

                        // Age
                        TextField("Age", text: $age)
                            .keyboardType(.numberPad)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .foregroundColor(.black)
                            .padding(.horizontal)

                        // Description
                        TextEditor(text: $descriptionText)
                            .frame(height: 140)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .foregroundColor(.black)
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
                                .background(Color.blue.opacity(0.85))
                                .cornerRadius(16)
                                .shadow(color: .gray.opacity(0.4), radius: 6, x: 0, y: 4)
                                .padding(.horizontal, 24)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
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
            name: name,
            age: ageInt,
            description: descriptionText,
            imageFileNames: filenames
        )

        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: "\(userType)_profile")
        }

        onSaved(profile)
        presentationMode.wrappedValue.dismiss()
    }
}

