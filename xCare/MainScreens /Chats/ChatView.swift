import SwiftUI
import PhotosUI

struct ChatView: View {
    let chatId: String
    let otherUser: String       // ex: "Alice, 25" (UI only)
    let otherUserEmail: String  // ✅ hidden, used internally
    
    @State private var messages: [String] = []
    @State private var newMessage: String = ""
    @State private var myEmail: String = UserDefaults.standard.string(forKey: "loggedInEmail") ?? ""
    @Environment(\.dismiss) private var dismiss
    
    // For "+" button
    @State private var showOptions = false
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    
    // For viewing profile
    @State private var showProfile = false
    @State private var otherUserProfile: UserProfile?

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
                    .foregroundColor(.black)
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 2)

                // "+" button
                Button(action: { showOptions = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .clipShape(Circle())
                        .shadow(radius: 3)
                }

                // Send button
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
            .background(Color(red: 0.96, green: 0.95, blue: 0.90))
        }
        .background(Color(red: 0.96, green: 0.95, blue: 0.90).ignoresSafeArea())
        .onAppear {
            loadMessages()
            loadOtherUserProfile()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Custom bubble name in center
            ToolbarItem(placement: .principal) {
                Button(action: { showProfile = true }) {
                    Text(otherUser)
                        .font(.headline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(radius: 2)
                }
            }
        }
        // Options for "+" button
        .confirmationDialog("Send...", isPresented: $showOptions, titleVisibility: .visible) {
            Button("Send a Picture") { showImagePicker = true }
            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(isPresented: $showImagePicker, selection: .constant(nil))
        // Profile viewer sheet
        .sheet(isPresented: $showProfile) {
            if let profile = otherUserProfile {
                ProfileViewerView(profile: profile)
            } else {
                Text("No profile available")
            }
        }
        // ✅ Tap anywhere to dismiss keyboard
        .onTapGesture { hideKeyboard() }
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
        hideKeyboard()
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

    // MARK: - Load other user profile
    private func loadOtherUserProfile() {
        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys {
            if key.hasSuffix(otherUserEmail),
               let data = defaults.data(forKey: key),
               let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
                otherUserProfile = profile
                return
            }
        }
    }
}

// MARK: - Read-only Profile Viewer
struct ProfileViewerView: View {
    let profile: UserProfile
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let firstImage = profile.imageFileNames.first,
                   let uiImage = FileStorageHelpers.loadImageFromDocuments(filename: firstImage) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 300)
                        .clipped()
                        .cornerRadius(20)
                        .shadow(radius: 6)
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.gray)
                        .padding(.top, 40)
                }
                
                Text("\(profile.name), \(profile.age)")
                    .font(.title.bold())
                    .foregroundColor(.blue)
                
                Text(profile.description)
                    .font(.body)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                    .padding()
                
                Spacer()
            }
            .padding()
        }
        .background(Color(red: 0.96, green: 0.95, blue: 0.90).ignoresSafeArea())
    }
}

// MARK: - Hide Keyboard Helper
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}

