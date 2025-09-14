import SwiftUI

extension Notification.Name {
    static let profilesUpdated = Notification.Name("profilesUpdated")
}

struct HomeView: View {
    @State private var dragOffset: CGSize = .zero
    @State private var loggedInUserType: String = UserDefaults.standard.string(forKey: "loggedInUserType") ?? "nanny"
    @State private var loggedInEmail: String = UserDefaults.standard.string(forKey: "loggedInEmail") ?? ""
    @State private var profiles: [UserProfile] = []
    @State private var currentUserProfile: UserProfile?
    @State private var showProfileEditor = false
    @State private var profileIncomplete = false
    @State private var cachedImages: [UUID: UIImage] = [:]

    // Chat / matching
    @State private var showChatList = false
    @State private var likedProfiles: Set<String> = []
    @State private var matches: [String] = UserDefaults.standard.stringArray(forKey: "matches") ?? []
    @State private var showMatchAlert = false
    @State private var matchedName: String = ""

    // Preload ChatListView
    @State private var preloadedChatListView: ChatListView?

    // Button animations
    @State private var isChatButtonPressed = false
    @State private var isProfileButtonPressed = false

    private let cardHeight: CGFloat = 500
    private let swipeThreshold: CGFloat = 120

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.96, green: 0.95, blue: 0.90).ignoresSafeArea()

                VStack {
                    // Top bar
                    HStack {
                        // Chat button with bounce
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                isChatButtonPressed = true
                            }
                            withAnimation(.spring().delay(0.15)) {
                                isChatButtonPressed = false
                            }
                            showChatList = true   // ✅ open immediately
                        }) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }
                        .scaleEffect(isChatButtonPressed ? 0.85 : 1.0)

                        Spacer()

                        // Profile button with bounce
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                isProfileButtonPressed = true
                            }
                            withAnimation(.spring().delay(0.15)) {
                                isProfileButtonPressed = false
                            }
                            showProfileEditor = true
                        }) {
                            Image(systemName: "person.crop.circle")
                                .font(.title)
                                .foregroundColor(.blue)
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }
                        .scaleEffect(isProfileButtonPressed ? 0.85 : 1.0)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    Spacer().frame(height: 40)

                    // Card stack
                    if profileIncomplete {
                        profileMissingView
                            .frame(height: cardHeight)
                            .padding(.horizontal, 20)
                    } else if profiles.isEmpty {
                        Text("No profiles to show")
                            .foregroundColor(.gray)
                            .frame(height: cardHeight)
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(20)
                            .shadow(radius: 6)
                            .padding(.horizontal, 20)
                    } else {
                        ZStack {
                            ForEach(profiles) { profile in
                                let isTopCard = profile.id == profiles.last?.id
                                profileCard(profile, isTopCard: isTopCard)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    Spacer()
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showProfileEditor) {
                if !loggedInEmail.isEmpty {
                    ProfileEditorView(
                        userType: loggedInUserType,
                        email: loggedInEmail,
                        existingProfile: currentUserProfile
                    ) { saved in
                        saveProfile(saved)
                        loadProfiles()
                        profileIncomplete = false
                    }
                } else {
                    Text("Error: No logged-in email found")
                }
            }
            .fullScreenCover(isPresented: $showChatList) {
                if let chatListView = preloadedChatListView {
                    NavigationStack {
                        chatListView
                            .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    Button("Close") { showChatList = false }
                                }
                            }
                    }
                }
            }
            .onAppear {
                loadProfiles()
                // 👂 Listen for live profile updates
                NotificationCenter.default.addObserver(forName: .profilesUpdated, object: nil, queue: .main) { _ in
                    loadProfiles()
                }
                // ✅ Preload ChatListView
                if preloadedChatListView == nil {
                    preloadedChatListView = ChatListView(matches: $matches)
                }
            }
            .alert(isPresented: $showMatchAlert) {
                Alert(
                    title: Text("🎉 It's a Match!"),
                    message: Text("You matched with \(matchedName)"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    // MARK: - Profile Missing View
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
    }

    // MARK: - Profile Card
    private func profileCard(_ profile: UserProfile, isTopCard: Bool) -> some View {
        ZStack {
            if let uiImage = cachedImages[profile.id] {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width - 80, height: cardHeight)
                    .clipped()
            } else {
                Color.gray.opacity(0.4)
                    .frame(width: UIScreen.main.bounds.width - 80, height: cardHeight)
                    .overlay(Text("No photo").foregroundColor(.white))
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
            }

            if isTopCard {
                HStack {
                    if dragOffset.width > 0 {
                        Text("LIKE ❤️")
                            .font(.largeTitle.bold())
                            .foregroundColor(.green)
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.green, lineWidth: 4)
                            )
                            .rotationEffect(.degrees(-15))
                            .opacity(Double(min(dragOffset.width / swipeThreshold, 1)))
                            .padding(.top, 40)
                            .padding(.leading, 20)
                        Spacer()
                    } else if dragOffset.width < 0 {
                        Spacer()
                        Text("NOPE ❌")
                            .font(.largeTitle.bold())
                            .foregroundColor(.red)
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.red, lineWidth: 4)
                            )
                            .rotationEffect(.degrees(15))
                            .opacity(Double(min(-dragOffset.width / swipeThreshold, 1)))
                            .padding(.top, 40)
                            .padding(.trailing, 20)
                    }
                }
            }
        }
        .frame(height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 6)
        .padding(20)
        .offset(x: isTopCard ? dragOffset.width : 0,
                y: isTopCard ? dragOffset.height / 10 : 0)
        .rotationEffect(.degrees(isTopCard ? Double(dragOffset.width / 25) : 0))
        .scaleEffect(isTopCard ? 1.0 - min(abs(dragOffset.width) / 1000, 0.1) : 1.0)
        .animation(.spring(), value: dragOffset)
        .gesture(
            isTopCard ? DragGesture()
                .onChanged { dragOffset = $0.translation }
                .onEnded { value in
                    if value.translation.width > swipeThreshold {
                        handleLike(profile)
                    } else if value.translation.width < -swipeThreshold {
                        _ = profiles.popLast()
                    }
                    dragOffset = .zero
                } : nil
        )
    }

    // MARK: - Likes & Matches
    private func handleLike(_ profile: UserProfile) {
        likedProfiles.insert(profile.email)
        saveLike(for: profile.email)

        if otherUserLikedMe(profile.email) {
            matches.append(profile.email)
            saveMatch(with: profile.email)
            matchedName = profile.name
            showMatchAlert = true
        }

        _ = profiles.popLast()
    }

    private func saveLike(for email: String) {
        var likes = UserDefaults.standard.stringArray(forKey: "likes_\(loggedInEmail)") ?? []
        if !likes.contains(email) { likes.append(email) }
        UserDefaults.standard.set(likes, forKey: "likes_\(loggedInEmail)")
    }

    private func otherUserLikedMe(_ email: String) -> Bool {
        let otherLikes = UserDefaults.standard.stringArray(forKey: "likes_\(email)") ?? []
        return otherLikes.contains(loggedInEmail)
    }

    private func saveMatch(with email: String) {
        var allMatches = UserDefaults.standard.stringArray(forKey: "matches") ?? []
        if !allMatches.contains(email) { allMatches.append(email) }
        UserDefaults.standard.set(allMatches, forKey: "matches")
        matches = allMatches  // ✅ keep state in sync
    }

    // MARK: - Profile Management
    private func saveProfile(_ profile: UserProfile) {
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: "\(profile.userType)_profile_\(profile.email)")
        }
        currentUserProfile = profile

        // 🔔 Trigger live update
        NotificationCenter.default.post(name: .profilesUpdated, object: nil)
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
                        if loggedInUserType == "nanny" && decoded.userType == "parent" {
                            loaded.append(decoded)
                        } else if loggedInUserType == "parent" && decoded.userType == "nanny" {
                            loaded.append(decoded)
                        }
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

        profiles = loaded

        cachedImages.removeAll()
        for profile in profiles {
            if let firstImage = profile.imageFileNames.first,
               let uiImage = FileStorageHelpers.loadImageFromDocuments(filename: firstImage) {
                cachedImages[profile.id] = uiImage
            }
        }
    }
}

