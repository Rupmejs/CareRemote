import SwiftUI

struct ChatListView: View {
    @State var matches: [String]
    @State private var myEmail: String = UserDefaults.standard.string(forKey: "loggedInEmail") ?? ""

    var body: some View {
        List {
            ForEach(matches, id: \.self) { email in
                let chatId = makeChatId(with: email)
                if let preview = UserDefaults.standard.stringArray(forKey: "chat_\(chatId)")?.last {
                    NavigationLink(destination: ChatView(chatId: chatId, otherUser: email)) {
                        chatRow(email: email, preview: preview)
                    }
                } else {
                    // If no messages, show placeholder preview
                    NavigationLink(destination: ChatView(chatId: chatId, otherUser: email)) {
                        chatRow(email: email, preview: "Say hi 👋")
                    }
                }
            }
            .onDelete(perform: deleteChat) // swipe-to-delete option
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Chats")
        .background(Color(red: 0.96, green: 0.95, blue: 0.90).ignoresSafeArea())
        .onAppear {
            cleanUpDeletedChats()
        }
    }

    // MARK: - Chat row design
    private func chatRow(email: String, preview: String) -> some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .font(.largeTitle)
                .foregroundColor(.blue)
            VStack(alignment: .leading) {
                Text(email)
                    .font(.headline)
                Text(preview)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Ensure unique shared chatId
    private func makeChatId(with other: String) -> String {
        return [myEmail, other].sorted().joined(separator: "_")
    }

    // MARK: - Delete chat manually from list
    private func deleteChat(at offsets: IndexSet) {
        for index in offsets {
            let email = matches[index]
            let chatId = makeChatId(with: email)
            UserDefaults.standard.removeObject(forKey: "chat_\(chatId)")
            UserDefaults.standard.removeObject(forKey: "chatPreview_\(chatId)")
        }
        matches.remove(atOffsets: offsets)
    }

    // MARK: - Clean up deleted chats
    private func cleanUpDeletedChats() {
        matches = matches.filter { email in
            let chatId = makeChatId(with: email)
            return UserDefaults.standard.stringArray(forKey: "chat_\(chatId)") != nil
        }
    }
}

