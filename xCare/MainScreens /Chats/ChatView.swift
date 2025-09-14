import SwiftUI

struct ChatView: View {
    let chatId: String
    let otherUser: String
    
    @State private var messages: [String] = []
    @State private var newMessage: String = ""
    @State private var myEmail: String = UserDefaults.standard.string(forKey: "loggedInEmail") ?? ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            // Messages scroll
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(messages.indices, id: \.self) { index in
                            chatBubble(messages[index])
                                .id(index)
                        }
                    }
                    .padding(.vertical, 10)
                }
                .onChange(of: messages) { _ in
                    withAnimation {
                        proxy.scrollTo(messages.count - 1, anchor: .bottom)
                    }
                }
            }

            // Input bar
            HStack(spacing: 12) {
                TextField("Type a message...", text: $newMessage)
                    .foregroundColor(.black) // ✅ text color
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 2)

                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 3)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(red: 0.96, green: 0.95, blue: 0.90)) // matches HomeView
        }
        .background(Color(red: 0.96, green: 0.95, blue: 0.90).ignoresSafeArea())
        .onAppear { loadMessages() }
        .navigationTitle(otherUser)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // ✅ Delete conversation button
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive) {
                    deleteConversation()
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
    }

    // MARK: - Bubble design
    private func chatBubble(_ msg: String) -> some View {
        let sender = msg.split(separator: ":", maxSplits: 1).map(String.init)
        let isMe = sender.first == myEmail
        let text = sender.count > 1 ? sender[1] : msg

        return HStack {
            if isMe { Spacer() }
            Text(text)
                .padding()
                .foregroundColor(isMe ? .white : .black)
                .background(isMe ? Color.blue.opacity(0.85) : Color.white)
                .cornerRadius(16)
                .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
                .frame(maxWidth: UIScreen.main.bounds.width * 0.7,
                       alignment: isMe ? .trailing : .leading)
            if !isMe { Spacer() }
        }
        .padding(.horizontal)
        .padding(.vertical, 2)
    }

    // MARK: - Messaging
    private func sendMessage() {
        guard !newMessage.isEmpty else { return }
        let msg = "\(myEmail):\(newMessage)"
        messages.append(msg)
        saveMessages()
        newMessage = ""
    }

    private func loadMessages() {
        if let saved = UserDefaults.standard.stringArray(forKey: "chat_\(chatId)") {
            messages = saved
        }
    }

    private func saveMessages() {
        UserDefaults.standard.set(messages, forKey: "chat_\(chatId)")
        UserDefaults.standard.set(messages.last, forKey: "chatPreview_\(chatId)")
    }

    // MARK: - Delete conversation
    private func deleteConversation() {
        UserDefaults.standard.removeObject(forKey: "chat_\(chatId)")
        UserDefaults.standard.removeObject(forKey: "chatPreview_\(chatId)")
        messages.removeAll()
        dismiss() // go back to chat list
    }
}

