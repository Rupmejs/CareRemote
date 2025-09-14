import SwiftUI

struct HomeView: View {
    @State private var dragOffset: CGSize = .zero
    @State private var loggedInUserType: String = UserDefaults.standard.string(forKey: "loggedInUserType") ?? "nanny"
    @State private var loggedInEmail: String = UserDefaults.standard.string(forKey: "loggedInEmail") ?? ""
    @State private var profiles: [UserProfile] = []
    @State private var currentUserProfile: UserProfile?
    @State private var showProfileEditor = false
    @State private var profileIncomplete = false
    @State private var cachedImages: [UUID: UIImage] = [:]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topTrailing) {
                Color(red: 0.96, green: 0.95, blue: 0.90).ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("xCare")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                        .padding(.top, 60)

                    Spacer()

                    if profileIncomplete {
                        profileMissingView
                    } else {
                        if profiles.isEmpty {
                            Text("No profiles to show")
                                .foregroundColor(.gray)
                        } else {
                            ZStack {
                                ForEach(profiles) { profile in
                                    profileCard(profile)
                                        .zIndex(profile.id == profiles.last?.id ? 1 : 0)
                                }
                            }
                        }
                        Spacer()
                    }
                }

                Button(action: { showProfileEditor = true }) {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                        .shadow(radius: 3)
                        .padding(.trailing, 16)
                        .padding(.top, 60)
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showProfileEditor) {
                if !loggedInEmail.isEmpty {
                    ProfileEditorView(
                        userType: loggedInUserType,
                        email: loggedInEmail,
                        existingProfile: currentUserProfile    // ✅ pass existing profile
                    ) { saved in
                        saveProfile(saved)
                        loadProfiles()
                        profileIncomplete = false
                    }
                } else {
                    Text("Error: No logged-in email found")
                }
            }
            .onAppear { loadProfiles() }
        }
    }

    private var profileMissingView: some View {
        VStack(spacing: 16) {
            Text("No profile found")
                .font(.headline)
                .foregroundColor(.black)

            Button(action: { showProfileEditor = true }) {
                Text("Create Profile")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.85))
                    .cornerRadius(16)
                    .shadow(color: .gray.opacity(0.4), radius: 6, x: 0, y: 4)
            }
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(20)
        .shadow(color: .gray.opacity(0.3), radius: 10, x: 0, y: 6)
        .padding(.horizontal, 24)
    }

    private func profileCard(_ profile: UserProfile) -> some View {
        ZStack {
            if let uiImage = cachedImages[profile.id] {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 480)
                    .clipped()
                    .cornerRadius(28)
                    .shadow(radius: 6)
            } else {
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.gray.opacity(0.4))
                    .frame(height: 480)
                    .overlay(
                        Text("No photo")
                            .foregroundColor(.white)
                            .font(.title2.bold())
                    )
            }

            VStack {
                Spacer()
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(profile.name), \(profile.age)")
                            .font(.title.bold())
                            .foregroundColor(.white)
                            .shadow(radius: 2)

                        Text(profile.description)
                            .foregroundColor(.white)
                            .lineLimit(3)
                            .shadow(radius: 1)
                    }
                    Spacer()
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.black.opacity(0.6), Color.clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(20)
            }
        }
        .offset(x: profile.id == profiles.last?.id ? dragOffset.width : 0)
        .rotationEffect(.degrees(profile.id == profiles.last?.id ? Double(dragOffset.width / 25) : 0))
        .gesture(
            profile.id == profiles.last?.id ? DragGesture()
                .onChanged { dragOffset = $0.translation }
                .onEnded { value in
                    if abs(value.translation.width) > 120 {
                        withAnimation(.spring()) {
                            _ = profiles.popLast()
                        }
                    }
                    dragOffset = .zero
                } : nil
        )
        .padding(.horizontal, 20)
    }

    private func saveProfile(_ profile: UserProfile) {
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: "\(profile.userType)_profile_\(profile.email)")
        }
        currentUserProfile = profile
    }

    private func loadProfiles() {
        guard !loggedInEmail.isEmpty else {
            profileIncomplete = true
            return
        }

        var loaded: [UserProfile] = []
        var myProfile: UserProfile?

        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys {
            if key.hasPrefix("nanny_profile_") || key.hasPrefix("parent_profile_") {
                if let data = defaults.data(forKey: key),
                   let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
                    if decoded.email == loggedInEmail {
                        myProfile = decoded
                    } else {
                        loaded.append(decoded)
                    }
                }
            }
        }

        if let myProfile = myProfile {
            currentUserProfile = myProfile
            profileIncomplete = false
        } else {
            profileIncomplete = true
        }

        profiles = loaded.reversed()

        cachedImages.removeAll()
        for profile in profiles {
            if let firstImage = profile.imageFileNames.first,
               let uiImage = FileStorageHelpers.loadImageFromDocuments(filename: firstImage) {
                cachedImages[profile.id] = uiImage
            }
        }
    }
}

