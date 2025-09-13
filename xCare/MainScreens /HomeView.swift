import SwiftUI

struct HomeView: View {
    @State private var dragOffset: CGSize = .zero
    @State private var loggedInUserType: String = UserDefaults.standard.string(forKey: "loggedInUserType") ?? "nanny"
    @State private var userProfile: UserProfile?
    @State private var showProfileEditor = false
    @State private var profileIncomplete = false
    @State private var cachedImage: UIImage? // cache first image

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.96, green: 0.95, blue: 0.90).ignoresSafeArea()

                VStack(spacing: 20) {
                    // Title
                    Text("xCare")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                        .padding(.top, 60)

                    Spacer()

                    if profileIncomplete {
                        profileMissingView
                    } else {
                        if let profile = userProfile {
                            profileCard(profile)
                        } else {
                            Text("No profile found")
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showProfileEditor) {
                ProfileEditorView(userType: loggedInUserType) { saved in
                    if let encoded = try? JSONEncoder().encode(saved) {
                        UserDefaults.standard.set(encoded, forKey: "\(loggedInUserType)_profile")
                    }
                    userProfile = saved
                    loadCachedImage(for: saved)
                    profileIncomplete = false
                }
            }
            .onAppear { checkProfile() }
        }
    }

    // MARK: - Subviews

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
            if let uiImage = cachedImage {
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
                        Text(profile.name)
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
        .offset(x: dragOffset.width)
        .rotationEffect(.degrees(Double(dragOffset.width / 25)))
        .gesture(
            DragGesture()
                .onChanged { dragOffset = $0.translation }
                .onEnded { value in
                    withAnimation(.spring()) {
                        if value.translation.width > 120 || value.translation.width < -120 {
                            dragOffset = .zero // here you could trigger next profile
                        } else {
                            dragOffset = .zero
                        }
                    }
                }
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Helpers

    private func checkProfile() {
        if let data = UserDefaults.standard.data(forKey: "\(loggedInUserType)_profile"),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            userProfile = decoded
            loadCachedImage(for: decoded)
            profileIncomplete = false
        } else {
            profileIncomplete = true
        }
    }

    private func loadCachedImage(for profile: UserProfile) {
        if let firstImage = profile.imageFileNames.first {
            cachedImage = FileStorageHelpers.loadImageFromDocuments(filename: firstImage)
        }
    }
}

