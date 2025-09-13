import SwiftUI

struct ProfileEditorView: View {
    @Environment(\.presentationMode) var presentationMode

    @State private var name: String = ""
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
                    VStack(spacing: 20) {
                        Text("Create your profile")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(red: 0.3, green: 0.6, blue: 1.0))
                            .padding(.top, 24)

                        // Add Photo
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(uiImages.enumerated()), id: \.offset) { idx, img in
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 140, height: 140)
                                        .clipped()
                                        .cornerRadius(12)
                                }
                                Button("Add Photos") {
                                    showingPicker = true
                                }
                                .frame(width: 140, height: 140)
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(radius: 2)
                            }
                            .padding(.horizontal)
                        }

                        // Name
                        TextField("Full name", text: $name)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .foregroundColor(.black)
                            .padding(.horizontal)

                        // Description
                        TextEditor(text: $descriptionText)
                            .frame(height: 140)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .foregroundColor(.black)
                            .padding(.horizontal)

                        if let error = errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }

                        Button(action: saveProfile) {
                            Text("Save & Continue")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                                .padding(.horizontal)
                        }
                    }
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

        let profile = UserProfile(userType: userType, name: name, description: descriptionText, imageFileNames: filenames)

        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: "\(userType)_profile")
        }

        onSaved(profile)
        presentationMode.wrappedValue.dismiss()
    }
}

