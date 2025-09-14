import SwiftUI

struct ChatView: View {
    let chatId: String
    @State private var messages: [String] = []
    @State private var newMessage: String = ""

    var body: some View {
        VStack {
            ScrollView {
                ForEach(messages, id: \.self) { msg in
                    HStack {
                        if msg.starts(with: "me:") {
                            Spacer()
                            Text(msg.replacingOccurrences(of: "me:", with: ""))
                                .padding()
                                .background(Color.blue.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        } else {
                            Text(msg)
                                .padding()
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(12)
                            Spacer()
                        }
                    }
                    .padding(.horizontal)
                }
            }

            HStack {
                TextField("Type a message...", text: $newMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .clipShape(Circle())
                }
            }
            .padding()
        }
        .onAppear { loadMessages() }
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sendMessage() {
        guard !newMessage.isEmpty else { return }
        messages.append("me:" + newMessage)
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
    }
}

