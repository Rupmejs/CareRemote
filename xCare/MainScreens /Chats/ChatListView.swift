import SwiftUI

struct ChatListView: View {
    @State var matches: [String]
    @State private var myEmail: String = UserDefaults.standard.string(forKey: "loggedInEmail") ?? ""

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
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(matches, id: \.self) { email in
                            let chatId = makeChatId(with: email)
                            let preview = UserDefaults.standard.string(forKey: "chatPreview_\(chatId)") ?? "Say hi 👋"

                            // Load profile for display
                            let profile = loadProfile(for: email)
                            let displayName = profile.map { "\($0.name), \($0.age)" } ?? email
                            let profileImage = profile?.imageFileNames.first.flatMap {
                                FileStorageHelpers.loadImageFromDocuments(filename: $0)
                            }

                            NavigationLink(destination: ChatView(chatId: chatId, otherUser: displayName)) {
                                HStack(spacing: 16) {
                                    if let uiImage = profileImage {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 48, height: 48)
                                            .clipShape(Circle())
                                            .shadow(radius: 3)
                                    } else {
                                        Image(systemName: "person.circle.fill")
                                            .font(.system(size: 48))
                                            .foregroundColor(.blue)
                                    }

                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(displayName)
                                            .font(.headline.bold())
                                            .foregroundColor(.black)

                                        Text(preview)
                                            .font(.subheadline)
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
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
            }
        }
        // ✅ Toolbar items stay, background disappears
        .toolbarBackground(.clear, for: .navigationBar)   // transparent background
        .toolbarBackground(.visible, for: .navigationBar) // keep toolbar visible
        .navigationTitle("Chats")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Chats")
                    .font(.headline.bold())
                    .foregroundColor(.blue) // Title always blue
            }
        }
    }

    private func makeChatId(with other: String) -> String {
        return [myEmail, other].sorted().joined(separator: "_")
    }

    private func loadProfile(for email: String) -> UserProfile? {
        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys {
            if key.contains(email),
               let data = defaults.data(forKey: key),
               let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
                return profile
            }
        }
        return nil
    }
}

