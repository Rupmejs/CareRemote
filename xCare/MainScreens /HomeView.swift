import SwiftUI

extension Notification.Name {
    static let profilesUpdated = Notification.Name("profilesUpdated")
    static let newMessage = Notification.Name("newMessage") // 🔔 triggered from ChatView
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
    @State private var likedProfiles: Set<String> = []
    @State private var matches: [String] = UserDefaults.standard.stringArray(forKey: "matches") ?? []
    @State private var showMatchAlert = false
    @State private var matchedName: String = ""

    // Chat navigation
    @State private var selectedChat: (chatId: String, otherUser: String, email: String)? = nil
    @State private var showChatList = false

    // Unread counts
    @State private var unreadCounts: [String: Int] = [:]

    // Button animations
    @State private var isProfileButtonPressed = false

    private let cardHeight: CGFloat = 500
    private let swipeThreshold: CGFloat = 120

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.96, green: 0.95, blue: 0.90).ignoresSafeArea()

                VStack(spacing: 20) {
                    // Top bar
                    HStack {
                        Spacer()
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

                    // Matches Box
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.7))
                            .shadow(radius: 6)

                        VStack(spacing: 12) {
                            Text("Your Matches")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.blue)

                            if matches.isEmpty {
                                VStack(spacing: 10) {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                        .resizable()
                                        .frame(width: 70, height: 70)
                                        .foregroundColor(.blue.opacity(0.7))
                                    Text("No matches yet")
                                        .font(.headline)
                                        .foregroundColor(.black)
                                    Text("Swipe right on profiles to connect and start chatting!")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 20)
                                }
                                .padding(.vertical, 30)
                            } else {
                                HStack(spacing: 20) {
                                    ForEach(sortedMatches().prefix(3), id: \.self) { email in
                                        if let profile = loadProfile(for: email),
                                           let firstImage = profile.imageFileNames.first,
                                           let uiImage = FileStorageHelpers.loadImageFromDocuments(filename: firstImage) {
                                            Button {
                                                openChat(with: profile)
                                            } label: {
                                                VStack(spacing: 6) {
                                                    ZStack(alignment: .topTrailing) {
                                                        Image(uiImage: uiImage)
                                                            .resizable()
                                                            .scaledToFill()
                                                            .frame(width: 70, height: 70)
                                                            .clipShape(Circle())
                                                            .shadow(radius: 3)

                                                        if let count = unreadCounts[email], count > 0 {
                                                            Text("\(count)")
                                                                .font(.caption2).bold()
                                                                .foregroundColor(.white)
                                                                .padding(6)
                                                                .background(Color.red)
                                                                .clipShape(Circle())
                                                                .offset(x: 8, y: -8)
                                                        }
                                                    }
                                                    Text(profile.name)
                                                        .font(.caption)
                                                        .foregroundColor(.black)
                                                }
                                            }
                                        }
                                    }

                                    if matches.count > 3 {
                                        Button { showChatList = true } label: {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.blue.opacity(0.2))
                                                    .frame(width: 70, height: 70)
                                                Text("+\(matches.count - 3)")
                                                    .font(.headline)
                                                    .foregroundColor(.blue)
                                            }
                                            .shadow(radius: 3)
                                        }
                                    }
                                }
                                .padding(.vertical, 10)
                            }
                        }
                        .padding()
                    }
                    .padding(.horizontal, 20)

                    // Swipe Cards Container
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.7))
                            .shadow(radius: 6)

                        if profileIncomplete {
                            profileMissingView
                                .frame(height: cardHeight)
                                .padding(.horizontal, 20)
                        } else if profiles.isEmpty {
                            Text("No profiles to show")
                                .foregroundColor(.gray)
                                .frame(height: cardHeight)
                                .frame(maxWidth: .infinity)
                        } else {
                            ZStack {
                                ForEach(profiles) { profile in
                                    let isTopCard = profile.id == profiles.last?.id
                                    profileCard(profile, isTopCard: isTopCard)
                                }
                            }
                        }
                    }
                    .frame(height: cardHeight + 60)
                    .padding(.horizontal, 20)

                    Spacer()
                }

                // Hidden NavigationLink for ChatView
                NavigationLink(
                    destination: Group {
                        if let chat = selectedChat {
                            ChatView(
                                chatId: chat.chatId,
                                otherUser: chat.otherUser,
                                otherUserEmail: chat.email
                            )
                        } else {
                            EmptyView()
                        }
                    },
                    isActive: Binding(
                        get: { selectedChat != nil },
                        set: { if !$0 { selectedChat = nil } }
                    )
                ) { EmptyView() }
                .hidden()
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
                }
            }
            .fullScreenCover(isPresented: $showChatList) {
                NavigationStack {
                    ChatListView(matches: $matches)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Close") { showChatList = false }
                            }
                        }
                }
            }
            .onAppear {
                loadProfiles()
                loadUnreadCounts()
                NotificationCenter.default.addObserver(forName: .profilesUpdated, object: nil, queue: .main) { _ in
                    loadProfiles()
                    loadUnreadCounts()
                }
                NotificationCenter.default.addObserver(forName: .newMessage, object: nil, queue: .main) { note in
                    if let email = note.userInfo?["from"] as? String {
                        incrementUnread(for: email)
                    }
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

    // MARK: - Match Helpers
    private func loadProfile(for email: String) -> UserProfile? {
        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys {
            if key.hasSuffix(email),
               let data = defaults.data(forKey: key),
               let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
                return profile
            }
        }
        return nil
    }

    private func openChat(with profile: UserProfile) {
        let chatId = [loggedInEmail, profile.email].sorted().joined(separator: "_")
        let displayName = "\(profile.name), \(profile.age)"
        selectedChat = (chatId, displayName, profile.email)

        // Reset unread for this user
        let key = "unread_\(profile.email)"
        UserDefaults.standard.set(0, forKey: key)
        unreadCounts[profile.email] = 0
    }

    private func loadUnreadCounts() {
        var counts: [String: Int] = [:]
        for email in matches {
            let key = "unread_\(email)"
            counts[email] = UserDefaults.standard.integer(forKey: key)
        }
        unreadCounts = counts
    }

    private func incrementUnread(for email: String) {
        let key = "unread_\(email)"
        let current = UserDefaults.standard.integer(forKey: key)
        UserDefaults.standard.set(current + 1, forKey: key)
        unreadCounts[email] = current + 1

        // Save last message timestamp for sorting
        let tKey = "lastmsg_\(email)"
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: tKey)
    }

    private func sortedMatches() -> [String] {
        matches.sorted { a, b in
            let tA = UserDefaults.standard.double(forKey: "lastmsg_\(a)")
            let tB = UserDefaults.standard.double(forKey: "lastmsg_\(b)")
            return tA > tB
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
        matches = allMatches
    }

    // MARK: - Profile Management
    private func saveProfile(_ profile: UserProfile) {
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: "\(profile.userType)_profile_\(profile.email)")
        }
        currentUserProfile = profile
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

