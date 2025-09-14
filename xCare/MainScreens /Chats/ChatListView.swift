import SwiftUI

struct ChatListView: View {
    @Binding var matches: [String]   // ✅ Binding so it stays live
    @State private var myEmail: String = UserDefaults.standard.string(forKey: "loggedInEmail") ?? ""

    // For delete confirmation
    @State private var chatToDelete: (chatId: String, email: String)? = nil
    @State private var showDeleteConfirm = false

    var body: some View {
        ZStack {
            // Beige background
            Color(red: 0.96, green: 0.95, blue: 0.90).ignoresSafeArea()

            if matches.isEmpty {
                VStack {
                    Spacer()
                    Text("No chats yet")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .padding()
                    Spacer()
                }
            } else {
                // ✅ Use List (so swipe actions work) but render your box-style cards inside each row
                List {
                    ForEach(matches, id: \.self) { email in
                        let chatId = makeChatId(with: email)
                        let preview = UserDefaults.standard.string(forKey: "chatPreview_\(chatId)") ?? "Say hi 👋"

                        // Load profile for display
                        let profile = loadProfile(for: email)
                        let displayName = profile.map { "\($0.name), \($0.age)" } ?? "User"
                        let profileImage = profile?.imageFileNames.first.flatMap {
                            FileStorageHelpers.loadImageFromDocuments(filename: $0)
                        }

                        NavigationLink(
                            destination: ChatView(
                                chatId: chatId,
                                otherUser: displayName,
                                otherUserEmail: email // ✅ pass email internally; never shown
                            )
                        ) {
                            // 🔲 Your boxed card UI
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
                                    // Futuristic + bold username
                                    Text(displayName)
                                        .font(.system(size: 21, weight: .heavy, design: .rounded))
                                        .tracking(0.5)
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
                            .contentShape(Rectangle()) // better hit testing
                        }
                        // ✅ Swipe-to-delete with confirmation
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                chatToDelete = (chatId, email)
                                showDeleteConfirm = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .listRowBackground(Color.clear)        // keep beige background
                        .listRowSeparator(.hidden)              // hide row separators
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)) // breathing room
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden) // keep list transparent to show beige
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
        // 🗑️ Confirmation alert
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
        // Remove chat messages + preview
        UserDefaults.standard.removeObject(forKey: "chat_\(chatId)")
        UserDefaults.standard.removeObject(forKey: "chatPreview_\(chatId)")

        // Remove from matches (updates UI thanks to @Binding)
        if let idx = matches.firstIndex(of: email) {
            matches.remove(at: idx)
        }
    }
}

