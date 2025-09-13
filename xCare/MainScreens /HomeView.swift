import SwiftUI

struct HomeView: View {
    @State private var dragOffset: CGSize = .zero
    @State private var loggedInUserType: String = UserDefaults.standard.string(forKey: "loggedInUserType") ?? "nanny"
    @State private var loggedInEmail: String = UserDefaults.standard.string(forKey: "loggedInEmail") ?? ""
    @State private var userProfile: UserProfile?
    @State private var showProfileEditor = false
    @State private var profileIncomplete = false
    @State private var cachedImage: UIImage?

    var body: some View {
        NavigationStack {
            ZStack {
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
                if !loggedInEmail.isEmpty {
                    ProfileEditorView(userType: loggedInUserType, email: loggedInEmail) { saved in
                        if let encoded = try? JSONEncoder().encode(saved) {
                            UserDefaults.standard.set(encoded, forKey: "\(loggedInUserType)_profile")
                        }
                        userProfile = saved
                        loadCachedImage(for: saved)
                        profileIncomplete = false
                    }
                } else {
                    Text("Error: No logged-in email found")
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
        .offset(x: dragOffset.width)
        .rotationEffect(.degrees(Double(dragOffset.width / 25)))
        .gesture(
            DragGesture()
                .onChanged { dragOffset = $0.translation }
                .onEnded { _ in
                    withAnimation(.spring()) { dragOffset = .zero }
                }
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Helpers

    private func checkProfile() {
        guard !loggedInEmail.isEmpty else {
            profileIncomplete = true
            return
        }

        if let data = UserDefaults.standard.data(forKey: "\(loggedInUserType)_profile"),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: data),
           decoded.email == loggedInEmail,           // ✅ profile must match account
           !decoded.name.isEmpty,
           decoded.age > 0,
           !decoded.imageFileNames.isEmpty {
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

