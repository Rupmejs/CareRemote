import SwiftUI

struct ChatListView: View {
    @Binding var matches: [String]
    @State private var myEmail: String = UserDefaults.standard.string(forKey: "loggedInEmail") ?? ""
    @State private var myUserType: String = UserDefaults.standard.string(forKey: "loggedInUserType") ?? ""
    
    @State private var chatToDelete: (chatId: String, email: String)? = nil
    @State private var showDeleteConfirm = false
    @State private var searchText = ""
    
    // Real-time updates
    @State private var refreshTrigger = false
    
    var filteredMatches: [String] {
        if searchText.isEmpty {
            return sortedMatches()
        } else {
            return sortedMatches().filter { email in
                if let profile = loadProfile(for: email) {
                    return profile.name.localizedCaseInsensitiveContains(searchText)
                }
                return false
            }
        }
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.97, blue: 0.92),
                    Color(red: 0.94, green: 0.93, blue: 0.88)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header Section
                VStack(spacing: 16) {
                    // Search Bar
                    HStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray.opacity(0.6))
                                .font(.system(size: 16))
                            
                            TextField("Search conversations...", text: $searchText)
                                .font(.system(size: 16))
                                .foregroundColor(.black)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(25)
                        .shadow(color: .gray.opacity(0.1), radius: 3, x: 0, y: 2)
                        
                        if !searchText.isEmpty {
                            Button("Cancel") {
                                searchText = ""
                                hideKeyboard()
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // Stats Row
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(matches.count)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.blue)
                            
                            Text("Active Chats")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(getTotalUnreadCount())")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.orange)
                            
                            Text("Unread")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Subscription Banner (Enhanced)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.purple, Color.blue],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Premium Benefits")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Unlimited messaging • Priority support • Advanced matching")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.purple.opacity(0.8),
                                Color.blue.opacity(0.8),
                                Color.cyan.opacity(0.6)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(20)
                    .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 20)
                }
                .padding(.top, 10)

                // Chat List
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if filteredMatches.isEmpty {
                            // Empty state
                            VStack(spacing: 20) {
                                Spacer().frame(height: 60)
                                
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.1))
                                        .frame(width: 100, height: 100)
                                    
                                    Image(systemName: searchText.isEmpty ? "message.circle" : "magnifyingglass")
                                        .font(.system(size: 40))
                                        .foregroundColor(.blue.opacity(0.6))
                                }
                                
                                VStack(spacing: 8) {
                                    Text(searchText.isEmpty ? "No conversations yet" : "No results found")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.gray)
                                    
                                    Text(searchText.isEmpty ?
                                         "Start swiping to find your perfect match!" :
                                         "Try a different search term")
                                        .font(.system(size: 16))
                                        .foregroundColor(.gray.opacity(0.8))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 40)
                                }
                                
                                Spacer().frame(height: 100)
                            }
                        } else {
                            ForEach(filteredMatches, id: \.self) { email in
                                chatRowView(for: email)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle("Messages")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    Image(systemName: "message.badge.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                    
                    Text("Messages")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                }
            }
        }
        .toolbarBackground(
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.97, blue: 0.92),
                    Color(red: 0.94, green: 0.93, blue: 0.88)
                ],
                startPoint: .top,
                endPoint: .bottom
            ),
            for: .navigationBar
        )
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            startRefreshTimer()
        }
        .onTapGesture {
            hideKeyboard()
        }
        .alert("Delete Conversation?", isPresented: $showDeleteConfirm, actions: {
            Button("Delete", role: .destructive) {
                if let chat = chatToDelete {
                    deleteChat(chatId: chat.chatId, email: chat.email)
                }
            }
            Button("Cancel", role: .cancel) {
                chatToDelete = nil
            }
        }, message: {
            Text("This conversation will be permanently deleted and cannot be recovered.")
        })
    }

    // MARK: - Chat Row View
    private func chatRowView(for email: String) -> some View {
        let chatId = makeChatId(with: email)
        let profile = loadProfile(for: email)
        let displayName = profile.map { "\($0.name), \($0.age)" } ?? "User"
        let profileImage = profile?.imageFileNames.first.flatMap {
            FileStorageHelpers.loadImageFromDocuments(filename: $0)
        }
        let lastMessage = getLastMessage(for: chatId)
        let unreadCount = getUnreadCount(for: email)
        let hasJobOffer = lastMessage.contains("📋") || lastMessage.contains("Job offer")
        
        return NavigationLink(
            destination: ChatView(
                chatId: chatId,
                otherUser: displayName,
                otherUserEmail: email
            )
            .onAppear {
                // Mark as read when opening chat
                markAsRead(for: email)
            }
        ) {
            HStack(spacing: 16) {
                // Profile Image with Status
                ZStack(alignment: .topTrailing) {
                    ZStack(alignment: .bottomTrailing) {
                        if let uiImage = profileImage {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 64, height: 64)
                                .clipShape(Circle())
                                .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
                        } else {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.6), Color.blue.opacity(0.4)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 64, height: 64)
                                .overlay(
                                    Image(systemName: "person.crop.circle")
                                        .font(.system(size: 32))
                                        .foregroundColor(.white)
                                )
                                .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        
                        // Online status indicator
                        Circle()
                            .fill(Color.green)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                    
                    // Unread badge
                    if unreadCount > 0 {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 24, height: 24)
                            
                            Text("\(min(unreadCount, 99))")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .offset(x: 8, y: -8)
                        .shadow(color: .red.opacity(0.4), radius: 2, x: 0, y: 1)
                    }
                }

                // Message Content
                VStack(alignment: .leading, spacing: 6) {
                    // Name and Time
                    HStack {
                        HStack(spacing: 8) {
                            Text(profile?.name ?? "User")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black)
                            
                            if profile?.userType == "nanny" {
                                Image(systemName: "person.crop.circle.badge.checkmark")
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                            } else if profile?.userType == "parent" {
                                Image(systemName: "house.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.purple)
                            }
                        }
                        
                        Spacer()
                        
                        Text(getLastMessageTime(for: chatId))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(unreadCount > 0 ? .blue : .gray)
                    }
                    
                    // Last Message Preview
                    HStack(spacing: 8) {
                        if hasJobOffer {
                            HStack(spacing: 4) {
                                Image(systemName: "briefcase.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.purple)
                                
                                Text(lastMessage.replacingOccurrences(of: "📋 ", with: ""))
                                    .font(.system(size: 15, weight: unreadCount > 0 ? .semibold : .regular))
                                    .foregroundColor(unreadCount > 0 ? .black : .gray)
                                    .lineLimit(2)
                            }
                        } else {
                            Text(lastMessage)
                                .font(.system(size: 15, weight: unreadCount > 0 ? .semibold : .regular))
                                .foregroundColor(unreadCount > 0 ? .black : .gray)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                        
                        // Message status indicators
                        HStack(spacing: 4) {
                            if unreadCount > 0 {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 8, height: 8)
                            }
                            
                            if getLastMessageSender(for: chatId) == myEmail {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.blue.opacity(0.6))
                            }
                        }
                    }
                    
                    // Additional Info Row
                    HStack(spacing: 8) {
                        if let profile = profile {
                            Text("Age \(profile.age)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.7))
                                .cornerRadius(10)
                            
                            if hasJobOffer && unreadCount > 0 {
                                Text("New Offer")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.purple)
                                    .cornerRadius(10)
                            }
                        }
                        
                        Spacer()
                    }
                }

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray.opacity(0.6))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        unreadCount > 0 ?
                        LinearGradient(
                            colors: [Color.white, Color.blue.opacity(0.02)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color.white.opacity(0.9), Color.white.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: unreadCount > 0 ? .blue.opacity(0.2) : .gray.opacity(0.1),
                        radius: unreadCount > 0 ? 8 : 4,
                        x: 0,
                        y: 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        unreadCount > 0 ? Color.blue.opacity(0.3) : Color.clear,
                        lineWidth: unreadCount > 0 ? 1 : 0
                    )
            )
            .scaleEffect(unreadCount > 0 ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: unreadCount)
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(role: .destructive) {
                chatToDelete = (chatId, email)
                showDeleteConfirm = true
            } label: {
                Label("Delete Conversation", systemImage: "trash")
            }
            
            Button {
                markAsRead(for: email)
            } label: {
                Label(unreadCount > 0 ? "Mark as Read" : "Mark as Unread",
                      systemImage: unreadCount > 0 ? "envelope.open" : "envelope.badge")
            }
        }
    }

    // MARK: - Helper Functions
    private func makeChatId(with other: String) -> String {
        return [myEmail, other].sorted().joined(separator: "_")
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

    private func getUnreadCount(for email: String) -> Int {
        let unreadKey = "unread_\(myEmail)_from_\(email)"
        return UserDefaults.standard.integer(forKey: unreadKey)
    }
    
    private func getTotalUnreadCount() -> Int {
        var total = 0
        for email in matches {
            total += getUnreadCount(for: email)
        }
        return total
    }

    private func getLastMessage(for chatId: String) -> String {
        if let preview = UserDefaults.standard.string(forKey: "chatPreview_\(chatId)") {
            return preview
        }
        return "Say hi 👋"
    }
    
    private func getLastMessageTime(for chatId: String) -> String {
        let timestamp = UserDefaults.standard.double(forKey: "lastMessage_\(chatId)")
        if timestamp == 0 {
            return ""
        }
        
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        let calendar = Calendar.current
        let now = Date()
        
        // Check if it's today
        if calendar.isDate(date, inSameDayAs: now) {
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        
        // Check if it's yesterday
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday) {
            return "Yesterday"
        }
        
        // Check if it's within this week
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? Date()
        if date > weekAgo {
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
    
    private func getLastMessageSender(for chatId: String) -> String {
        if let data = UserDefaults.standard.data(forKey: "chat_\(chatId)"),
           let messages = try? JSONDecoder().decode([ChatMessage].self, from: data),
           let lastMessage = messages.last {
            return lastMessage.senderEmail
        }
        return ""
    }

    private func sortedMatches() -> [String] {
        return matches.sorted { a, b in
            let unreadA = getUnreadCount(for: a)
            let unreadB = getUnreadCount(for: b)
            
            // First priority: unread messages
            if unreadA != unreadB {
                return unreadA > unreadB
            }
            
            // Second priority: recent messages
            let timestampA = UserDefaults.standard.double(forKey: "lastMessage_\(makeChatId(with: a))")
            let timestampB = UserDefaults.standard.double(forKey: "lastMessage_\(makeChatId(with: b))")
            
            return timestampA > timestampB
        }
    }

    private func deleteChat(chatId: String, email: String) {
        UserDefaults.standard.removeObject(forKey: "chat_\(chatId)")
        UserDefaults.standard.removeObject(forKey: "chatPreview_\(chatId)")
        UserDefaults.standard.removeObject(forKey: "lastMessage_\(chatId)")
        UserDefaults.standard.removeObject(forKey: "unread_\(myEmail)_from_\(email)")
        
        if let idx = matches.firstIndex(of: email) {
            matches.remove(at: idx)
        }
        
        refreshTrigger.toggle()
    }
    
    private func markAsRead(for email: String) {
        let unreadKey = "unread_\(myEmail)_from_\(email)"
        UserDefaults.standard.set(0, forKey: unreadKey)
        refreshTrigger.toggle()
    }
    
    private func startRefreshTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            refreshTrigger.toggle()
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}
