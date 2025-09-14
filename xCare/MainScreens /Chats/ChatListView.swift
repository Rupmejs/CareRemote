import SwiftUI

struct ChatListView: View {
    @Binding var matches: [String]
    @State private var myEmail: String = UserDefaults.standard.string(forKey: "loggedInEmail") ?? ""

    @State private var chatToDelete: (chatId: String, email: String)? = nil
    @State private var showDeleteConfirm = false

    var body: some View {
        ZStack {
            // Beige background
            Color(red: 0.96, green: 0.95, blue: 0.90).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // 🔲 Subscription perks box
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Subscription Perks")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("• Unlimited chats\n• Priority support\n• More features coming soon")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(20)
                    .shadow(color: .gray.opacity(0.3), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    // 🔲 Chats list
                    if matches.isEmpty {
                        VStack {
                            Spacer(minLength: 60)
                            Text("No chats yet")
                                .font(.title2)
                                .foregroundColor(.gray)
                                .padding()
                            Spacer(minLength: 200)
                        }
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(matches, id: \.self) { email in
                                chatRow(for: email)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        // Toolbar styling
        .toolbarBackground(Color(red: 0.96, green: 0.95, blue: 0.90), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationTitle("Chats")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Chats")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
            }
        }
        // Delete confirmation
        .alert("Delete Chat?", isPresented: $showDeleteConfirm, actions: {
            Button("Delete", role: .destructive) {
                if let chat = chatToDelete {
                    deleteChat(chatId: chat.chatId, email: chat.email)
                }
            }
            Button("Cancel", role: .cancel) {
                chatToDelete = nil
            }
        }, message: {
            Text("This chat will be permanently deleted.")
        })
    }

    // MARK: - Chat Row Builder
    private func chatRow(for email: String) -> some View {
        let chatId = makeChatId(with: email)
        let preview = UserDefaults.standard.string(forKey: "chatPreview_\(chatId)") ?? "Say hi 👋"

        let profile = loadProfile(for: email)
        let displayName = profile.map { "\($0.name), \($0.age)" } ?? "User"
        let profileImage = profile?.imageFileNames.first.flatMap {
            FileStorageHelpers.loadImageFromDocuments(filename: $0)
        }

        return NavigationLink(
            destination: ChatView(
                chatId: chatId,
                otherUser: displayName,
                otherUserEmail: email
            )
        ) {
            HStack(spacing: 16) {
                if let uiImage = profileImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 54, height: 54)
                        .clipShape(Circle())
                        .shadow(radius: 3)
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 54))
                        .foregroundColor(.blue)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(displayName)
                        .font(.system(size: 21, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)

                    Text(preview)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding()
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: .gray.opacity(0.3), radius: 6, x: 0, y: 4)
        }
        // ✅ Context menu for delete
        .contextMenu {
            Button(role: .destructive) {
                chatToDelete = (chatId, email)
                showDeleteConfirm = true
            } label: {
                Label("Delete Chat", systemImage: "trash")
            }
        }
    }

    // MARK: - Helpers
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

    private func deleteChat(chatId: String, email: String) {
        UserDefaults.standard.removeObject(forKey: "chat_\(chatId)")
        UserDefaults.standard.removeObject(forKey: "chatPreview_\(chatId)")
        if let idx = matches.firstIndex(of: email) {
            matches.remove(at: idx)
        }
    }
}


