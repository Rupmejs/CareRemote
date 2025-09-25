import SwiftUI

// MARK: - Helper Functions

struct HomeView: View {
    @State private var dragOffset: CGSize = .zero
    @State private var loggedInUserType: String = UserDefaults.standard.string(forKey: "loggedInUserType") ?? "nanny"
    @State private var loggedInEmail: String = UserDefaults.standard.string(forKey: "loggedInEmail") ?? ""
    @State private var profiles: [UserProfile] = []
    @State private var currentUserProfile: UserProfile?
    @State private var showProfileEditor = false
    @State private var profileIncomplete = false

    // Chat / matching
    @State private var matches: [String] = UserDefaults.standard.stringArray(forKey: "matches") ?? []
    @State private var showMatchAlert = false
    @State private var matchedName: String = ""
    @State private var selectedChat: (chatId: String, otherUser: String, email: String)? = nil
    @State private var showChatList = false

    @EnvironmentObject var appState: AppState

    private let cardHeight: CGFloat = 500
    private let swipeThreshold: CGFloat = 120

    // MARK: - Dynamic texts
    private var matchesHeaderText: String {
        if loggedInUserType == "nanny" {
            return "👨‍👩‍👧‍👦 Your Families"
        } else if loggedInUserType == "parent" {
            return "🧑‍🍼 Your Nannies"
        } else {
            return "❤️ Your Matches"
        }
    }

    private var matchesEmptyText: String {
        if loggedInUserType == "nanny" {
            return "No families yet - start swiping!"
        } else if loggedInUserType == "parent" {
            return "No nannies yet - start swiping!"
        } else {
            return "No matches yet - start swiping!"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.96, green: 0.95, blue: 0.90).ignoresSafeArea()

                VStack(spacing: 15) {
                    // Top bar
                    HStack {
                        Button(action: { showProfileEditor = true }) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }

                        Spacer()

                        Text("Discover & Connect")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(LinearGradient(
                                colors: [Color(red: 0.4, green: 0.8, blue: 1.0), Color.blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    // Matches section
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.9))
                            .shadow(color: .gray.opacity(0.3), radius: 8, x: 0, y: 4)

                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .font(.title3)
                                    .foregroundColor(.pink)
                                Text(matchesHeaderText)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.blue)
                                Spacer()
                                if matches.count > 4 {
                                    Button("View All") { showChatList = true }
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal, 15)
                            .padding(.top, 10)

                            if matches.isEmpty {
                                VStack(spacing: 6) {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                        .font(.system(size: 20))
                                        .foregroundColor(.pink)
                                    
                                    Text(matchesEmptyText)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 8)
                            } else {
                                HStack(spacing: 12) {
                                    ForEach(Array(sortedMatches().prefix(4).enumerated()), id: \.offset) { _, email in
                                        if let profile = loadProfile(for: email) {
                                            Button(action: { openChat(with: profile) }) {
                                                VStack(spacing: 3) {
                                                    ZStack(alignment: .topTrailing) {
                                                        if let firstImage = profile.imageFileNames.first,
                                                           let uiImage = FileStorageHelpers.loadImageFromDocuments(filename: firstImage) {
                                                            Image(uiImage: uiImage)
                                                                .resizable()
                                                                .scaledToFill()
                                                                .frame(width: 50, height: 50)
                                                                .clipShape(Circle())
                                                                .shadow(color: .gray.opacity(0.3), radius: 2, x: 0, y: 1)
                                                        } else {
                                                            Circle()
                                                                .fill(Color.gray.opacity(0.3))
                                                                .frame(width: 50, height: 50)
                                                                .overlay(
                                                                    Image(systemName: "person.crop.circle")
                                                                        .font(.title3)
                                                                        .foregroundColor(.gray)
                                                                )
                                                        }

                                                        if getUnreadCount(for: email) > 0 {
                                                            Text("\(getUnreadCount(for: email))")
                                                                .font(.caption2).bold()
                                                                .foregroundColor(.white)
                                                                .frame(minWidth: 16, minHeight: 16)
                                                                .background(Color.red)
                                                                .clipShape(Circle())
                                                                .offset(x: 6, y: -6)
                                                        }
                                                    }
                                                    Text(profile.name)
                                                        .font(.system(size: 9, weight: .medium))
                                                        .foregroundColor(.black)
                                                        .lineLimit(1)
                                                }
                                            }
                                        }
                                    }

                                    if matches.count > 4 {
                                        Button(action: { showChatList = true }) {
                                            VStack(spacing: 3) {
                                                ZStack {
                                                    Circle()
                                                        .fill(Color.blue.opacity(0.1))
                                                        .frame(width: 50, height: 50)
                                                        .overlay(
                                                            Circle().stroke(Color.blue.opacity(0.3), lineWidth: 2)
                                                        )
                                                    
                                                    Text("+\(matches.count - 4)")
                                                        .font(.system(size: 14, weight: .bold))
                                                        .foregroundColor(.blue)
                                                }
                                                Text("more")
                                                    .font(.system(size: 9, weight: .medium))
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                    }

                                    Spacer()
                                }
                                .padding(.horizontal, 15)
                                .padding(.bottom, 8)
                            }
                        }
                    }
                    .padding(.horizontal, 15)

                    // Cards section (unchanged)
                    VStack(spacing: 8) {
                        Text("Swipe right to like, left to pass.")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        ZStack {
                            if profileIncomplete {
                                VStack(spacing: 25) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.blue.opacity(0.1))
                                            .frame(width: 120, height: 120)
                                        
                                        Image(systemName: "person.crop.circle.badge.plus")
                                            .font(.system(size: 50))
                                            .foregroundColor(.blue)
                                    }
                                    
                                    VStack(spacing: 12) {
                                        Text("Create Your Profile")
                                            .font(.system(size: 24, weight: .bold, design: .rounded))
                                            .foregroundColor(.blue)
                                        
                                        Text("Share your story and start connecting!")
                                            .font(.system(size: 16))
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 25)
                                    }

                                    Button("Create Profile") {
                                        showProfileEditor = true
                                    }
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(Color.blue)
                                    .cornerRadius(20)
                                    .shadow(color: .blue.opacity(0.4), radius: 12, x: 0, y: 6)
                                    .padding(.horizontal, 25)
                                }
                                .frame(height: cardHeight)
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .cornerRadius(25)
                                .shadow(color: .gray.opacity(0.2), radius: 15, x: 0, y: 8)
                                .padding(.horizontal, 15)
                            } else if profiles.isEmpty {
                                VStack(spacing: 25) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.orange.opacity(0.1))
                                            .frame(width: 120, height: 120)
                                        
                                        Image(systemName: "person.2.circle")
                                            .font(.system(size: 50))
                                            .foregroundColor(.orange)
                                    }
                                    
                                    VStack(spacing: 12) {
                                        Text("No Profiles Available")
                                            .font(.system(size: 22, weight: .bold, design: .rounded))
                                            .foregroundColor(.black)
                                        
                                        Text("Check back later for new connections!")
                                            .font(.system(size: 16))
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 25)
                                    }

                                    Button("Refresh") {
                                        loadProfiles()
                                    }
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 25)
                                    .padding(.vertical, 12)
                                    .background(Color.orange)
                                    .cornerRadius(20)
                                    .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                                }
                                .frame(height: cardHeight)
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .cornerRadius(25)
                                .shadow(color: .gray.opacity(0.2), radius: 15, x: 0, y: 8)
                                .padding(.horizontal, 15)
                            } else {
                                ForEach(profiles.indices, id: \.self) { index in
                                    let profile = profiles[index]
                                    let isTopCard = index == profiles.count - 1
                                    let cardOffset = CGFloat(profiles.count - 1 - index) * 6
                                    
                                    cardView(profile: profile, isTopCard: isTopCard)
                                        .offset(y: isTopCard ? 0 : cardOffset)
                                        .scaleEffect(isTopCard ? 1.0 : 1.0 - (CGFloat(profiles.count - 1 - index) * 0.03))
                                        .zIndex(isTopCard ? 1000 : Double(index))
                                }
                            }
                        }
                        .frame(height: cardHeight)
                    }

                    Spacer()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
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
            .onAppear { loadProfiles() }
            .alert("🎉 It's a Match!", isPresented: $showMatchAlert) {
                Button("OK") { }
            } message: {
                Text("You matched with \(matchedName)!")
            }
            .navigationDestination(isPresented: Binding(
                get: { selectedChat != nil },
                set: { if !$0 { selectedChat = nil } }
            )) {
                Group {
                    if let chat = selectedChat {
                        ChatView(
                            chatId: chat.chatId,
                            otherUser: chat.otherUser,
                            otherUserEmail: chat.email
                        )
                    } else {
                        EmptyView()
                    }
                }
            }
        }
    }

    // MARK: - Swipe Card
    private func cardView(profile: UserProfile, isTopCard: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            
            VStack(spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    if let firstImage = profile.imageFileNames.first,
                       let uiImage = FileStorageHelpers.loadImageFromDocuments(filename: firstImage) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: cardHeight)
                            .clipped()
                            .overlay(
                                LinearGradient(
                                    colors: [Color.clear, Color.clear, Color.black.opacity(0.6)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: cardHeight)
                            .overlay(
                                VStack(spacing: 10) {
                                    Image(systemName: "person.crop.circle")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray.opacity(0.6))
                                    Text("No Photo")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.gray.opacity(0.8))
                                }
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(profile.name), \(profile.age)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                        
                        Text(profile.description)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if isTopCard {
                        HStack {
                            if dragOffset.width > 50 {
                                VStack {
                                    HStack(spacing: 8) {
                                        Text("❤️").font(.system(size: 30))
                                        Text("LIKE")
                                            .font(.system(size: 24, weight: .black, design: .rounded))
                                    }
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(Color.white.opacity(0.95))
                                    .cornerRadius(30)
                                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                                    .rotationEffect(.degrees(-15))
                                    Spacer()
                                }
                                .padding(.top, 60)
                                .padding(.leading, 20)
                                Spacer()
                            } else if dragOffset.width < -50 {
                                Spacer()
                                VStack {
                                    HStack(spacing: 8) {
                                        Text("❌").font(.system(size: 30))
                                        Text("PASS")
                                            .font(.system(size: 24, weight: .black, design: .rounded))
                                    }
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(Color.white.opacity(0.95))
                                    .cornerRadius(30)
                                    .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
                                    .rotationEffect(.degrees(15))
                                    Spacer()
                                }
                                .padding(.top, 60)
                                .padding(.trailing, 20)
                            }
                        }
                    }
                }
                .cornerRadius(25)
            }
        }
        .frame(height: cardHeight)
        .frame(width: UIScreen.main.bounds.width - 50)
        .cornerRadius(25)
        .offset(x: isTopCard ? dragOffset.width : 0,
                y: isTopCard ? dragOffset.height / 15 : 0)
        .rotationEffect(.degrees(isTopCard ? Double(dragOffset.width / 25) : 0))
        .scaleEffect(isTopCard ? max(0.96, 1.0 - min(abs(dragOffset.width) / 1500, 0.04)) : 0.96)
        .gesture(
            isTopCard ?
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    if value.translation.width > swipeThreshold {
                        handleLike(profile)
                    } else if value.translation.width < -swipeThreshold {
                        removeProfile()
                    } else {
                        dragOffset = .zero
                    }
                } : nil
        )
    }

    // MARK: - Helpers
    private func getUnreadCount(for email: String) -> Int {
        let key = "unread_\(email)"
        return UserDefaults.standard.integer(forKey: key)
    }
    
    private func sortedMatches() -> [String] {
        return matches.sorted { a, b in
            let unreadA = getUnreadCount(for: a)
            let unreadB = getUnreadCount(for: b)
            if unreadA != unreadB { return unreadA > unreadB }
            let tA = UserDefaults.standard.double(forKey: "lastmsg_\(a)")
            let tB = UserDefaults.standard.double(forKey: "lastmsg_\(b)")
            return tA > tB
        }
    }

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
        
        let key = "unread_\(profile.email)"
        UserDefaults.standard.set(0, forKey: key)
    }

    private func handleLike(_ profile: UserProfile) {
        saveLike(for: profile.email)
        if otherUserLikedMe(profile.email) {
            matches.append(profile.email)
            saveMatch(with: profile.email)
            matchedName = profile.name
            showMatchAlert = true
        }
        removeProfile()
    }
    
    private func removeProfile() {
        withAnimation(.easeOut(duration: 0.4)) {
            dragOffset = CGSize(width: dragOffset.width > 0 ? 1200 : -1200, height: dragOffset.height)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            _ = profiles.popLast()
            dragOffset = .zero
        }
    }

    private func saveLike(for email: String) {
        var likes = UserDefaults.standard.stringArray(forKey: "likes_\(loggedInEmail)") ?? []
        if !likes.contains(email) {
            likes.append(email)
        }
        UserDefaults.standard.set(likes, forKey: "likes_\(loggedInEmail)")
    }

    private func otherUserLikedMe(_ email: String) -> Bool {
        let otherLikes = UserDefaults.standard.stringArray(forKey: "likes_\(email)") ?? []
        return otherLikes.contains(loggedInEmail)
    }

    private func saveMatch(with email: String) {
        var allMatches = UserDefaults.standard.stringArray(forKey: "matches") ?? []
        if !allMatches.contains(email) {
            allMatches.append(email)
        }
        UserDefaults.standard.set(allMatches, forKey: "matches")
        matches = allMatches
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
                        if loggedInUserType == "nanny" && decoded.userType == "parent" {
                            loaded.append(decoded)
                        } else if loggedInUserType == "parent" && decoded.userType == "nanny" {
                            loaded.append(decoded)
                        }
                    }
                }
            }
        }

        currentUserProfile = myProfile
        profileIncomplete = myProfile == nil
        profiles = loaded.shuffled()
    }
}

