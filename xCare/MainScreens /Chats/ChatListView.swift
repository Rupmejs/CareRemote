import SwiftUI

struct ChatListView: View {
    @State var matches: [String]

    var body: some View {
        NavigationStack {
            List(matches, id: \.self) { email in
                NavigationLink(destination: ChatView(chatId: email)) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                        Text(email)
                            .font(.headline)
                    }
                }
            }
            .navigationTitle("Chats")
        }
    }
}

