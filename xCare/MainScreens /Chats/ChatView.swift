import SwiftUI
import PhotosUI

struct ChatView: View {
    let chatId: String
    let otherUser: String       // ex: "Alice, 25" (UI only)
    let otherUserEmail: String  // ✅ hidden, used internally
    
    @State private var messages: [ChatMessage] = []
    @State private var newMessage: String = ""
    @State private var myEmail: String = UserDefaults.standard.string(forKey: "loggedInEmail") ?? ""
    @State private var myUserType: String = UserDefaults.standard.string(forKey: "loggedInUserType") ?? ""
    @Environment(\.dismiss) private var dismiss
    
    // For "+" button
    @State private var showOptions = false
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    
    // For job offer system
    @State private var showOfferPanel = false
    @State private var offerDescription = ""
    @State private var offerRate = ""
    @State private var offerStartDate = Date()
    @State private var offerEndDate = Date().addingTimeInterval(86400 * 7) // 1 week later
    @State private var offerDuration = "Weekly"
    
    // For viewing profile
    @State private var showProfile = false
    @State private var otherUserProfile: UserProfile?
    
    private let durationOptions = ["Hourly", "Daily", "Weekly", "Monthly"]

    var body: some View {
        ZStack {
            // Main chat interface
            VStack(spacing: 0) {
                // Messages scroll
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages.indices, id: \.self) { index in
                                chatBubble(messages[index])
                                    .id(index)
                            }
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 12)
                    }
                    .background(Color(red: 0.96, green: 0.95, blue: 0.90))
                    .onChange(of: messages) { _, _ in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if !messages.isEmpty {
                                proxy.scrollTo(messages.count - 1, anchor: .bottom)
                            }
                        }
                    }
                }

                // Input bar
                VStack(spacing: 0) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    HStack(spacing: 12) {
                        // Message input
                        HStack(spacing: 8) {
                            TextField("Type a message...", text: $newMessage, axis: .vertical)
                                .foregroundColor(.black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.white)
                                .cornerRadius(25)
                                .lineLimit(1...4)
                                .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
                        }
                        
                        // Action buttons
                        HStack(spacing: 8) {
                            // "+" button - only for parents to send offers
                            if myUserType == "parent" {
                                Button(action: {
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        showOfferPanel = true
                                    }
                                }) {
                                    Image(systemName: "briefcase.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 40)
                                        .background(
                                            LinearGradient(
                                                colors: [Color.purple, Color.blue],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .clipShape(Circle())
                                        .shadow(color: .purple.opacity(0.4), radius: 4, x: 0, y: 2)
                                }
                            }

                            // Send button
                            Button(action: sendMessage) {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.blue, Color.cyan],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .clipShape(Circle())
                                    .shadow(color: .blue.opacity(0.4), radius: 4, x: 0, y: 2)
                            }
                            .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .opacity(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.96, green: 0.95, blue: 0.90))
                }
            }
            
            // Job Offer Sliding Panel with semi-transparent overlay
            if showOfferPanel {
                jobOfferOverlay
            }
        }
        .onAppear {
            loadMessages()
            loadOtherUserProfile()
            markMessagesAsRead()
        }
        .onDisappear {
            markMessagesAsRead()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Casual profile header - clean and simple
            ToolbarItem(placement: .principal) {
                Button(action: { showProfile = true }) {
                    HStack(spacing: 12) {
                        // Simple profile image
                        ZStack {
                            if let profile = otherUserProfile,
                               let firstImage = profile.imageFileNames.first,
                               let uiImage = FileStorageHelpers.loadImageFromDocuments(filename: firstImage) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 38, height: 38)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                            } else {
                                Circle()
                                    .fill(Color.blue.opacity(0.8))
                                    .frame(width: 38, height: 38)
                                    .overlay(
                                        Image(systemName: "person.crop.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.white)
                                    )
                                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                            }
                        }
                        
                        // Clean name display
                        Text(otherUser)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                            .shadow(color: .white, radius: 1, x: 0, y: 0)
                    }
                }
            }
        }
        .sheet(isPresented: $showProfile) {
            if let profile = otherUserProfile {
                ProfileViewerView(profile: profile)
            } else {
                Text("No profile available")
            }
        }
        .onTapGesture { hideKeyboard() }
    }

    // MARK: - Job Offer Overlay
    private var jobOfferOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    hideKeyboard()
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showOfferPanel = false
                    }
                }
            
            VStack {
                Spacer()
                jobOfferPanel
                    .onTapGesture {
                        hideKeyboard()
                    }
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    private var jobOfferPanel: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 6)
                .padding(.top, 12)
            
            VStack(spacing: 20) {
                jobOfferHeader
                jobOfferContent
            }
        }
        .frame(maxWidth: .infinity)
        .background(jobOfferBackground)
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: -6)
        .gesture(jobOfferDragGesture)
    }
    
    private var jobOfferHeader: some View {
        HStack {
            Button("Cancel") {
                hideKeyboard()
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showOfferPanel = false
                }
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.red)
            .cornerRadius(20)
            
            Spacer()
            
            jobOfferTitle
            
            Spacer()
            
            jobOfferSendButton
        }
        .padding(.top, 20)
        .padding(.horizontal, 20)
    }
    
    private var jobOfferTitle: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.purple)
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: "briefcase.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text("Send Job Offer")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
            }
            
            Text("to \(otherUser)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
        }
    }
    
    private var jobOfferSendButton: some View {
        Button("Send") {
            hideKeyboard()
            sendJobOffer()
        }
        .font(.system(size: 16, weight: .bold))
        .foregroundColor(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(offerDescription.isEmpty || offerRate.isEmpty ? Color.gray : Color.green)
        .cornerRadius(20)
        .disabled(offerDescription.isEmpty || offerRate.isEmpty)
    }
    
    private var jobOfferContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                jobDescriptionSection
                rateAndDurationSection
                timePeriodSection
                
                Spacer().frame(height: 60)
            }
            .padding(.horizontal, 20)
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    private var jobDescriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Job Description")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $offerDescription)
                    .frame(height: 100)
                    .padding(12)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                    )
                    .scrollContentBackground(.hidden)
                
                if offerDescription.isEmpty {
                    Text("Describe the childcare needs, schedule, and any special requirements...")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                }
            }
            .onTapGesture {
                // Focus handling if needed
            }
        }
    }
    
    private var rateAndDurationSection: some View {
        HStack(spacing: 16) {
            rateSection
            durationSection
        }
    }
    
    private var rateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Rate")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
            
            HStack {
                Text("$")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.green)
                    .padding(.leading, 12)
                
                TextField("25", text: $offerRate)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                    .padding(.vertical, 12)
                    .padding(.trailing, 12)
            }
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Duration")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
            
            Menu {
                ForEach(durationOptions, id: \.self) { option in
                    Button(option) {
                        offerDuration = option
                        hideKeyboard()
                    }
                }
            } label: {
                HStack {
                    Text(offerDuration)
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                        .font(.system(size: 12))
                }
                .padding(12)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
    
    private var timePeriodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time Period")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
            
            VStack(spacing: 12) {
                DatePicker("Start Date", selection: $offerStartDate, displayedComponents: .date)
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                    )
                
                DatePicker("End Date", selection: $offerEndDate, displayedComponents: .date)
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
    
    private var jobOfferBackground: some View {
        Color(red: 0.96, green: 0.95, blue: 0.90)
            .opacity(0.85)
            .saturation(1.2)
            .blur(radius: 0.5)
    }
    
    private var jobOfferDragGesture: some Gesture {
        DragGesture()
            .onEnded { value in
                if value.translation.height > 100 {
                    hideKeyboard()
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showOfferPanel = false
                    }
                }
            }
    }

    // MARK: - Chat Bubble Design
    private func chatBubble(_ message: ChatMessage) -> some View {
        let isMe = message.senderEmail == myEmail
        
        return HStack {
            if isMe { Spacer(minLength: 60) }
            
            VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
                if message.type == .jobOffer {
                    jobOfferBubble(message, isMe: isMe)
                } else {
                    regularMessageBubble(message, isMe: isMe)
                }
                
                Text(timeAgo(message.timestamp))
                    .font(.system(size: 11))
                    .foregroundColor(.gray.opacity(0.8))
                    .padding(.horizontal, 4)
            }
            
            if !isMe { Spacer(minLength: 60) }
        }
    }
    
    private func regularMessageBubble(_ message: ChatMessage, isMe: Bool) -> some View {
        return Text(message.content)
            .font(.system(size: 16))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .foregroundColor(isMe ? .white : .black)
            .background(
                isMe ?
                LinearGradient(
                    colors: [Color.blue, Color.blue.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ) :
                LinearGradient(
                    colors: [Color.white, Color.white.opacity(0.95)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20, corners: isMe ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight])
            .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 2)
    }
    
    private func jobOfferBubble(_ message: ChatMessage, isMe: Bool) -> some View {
        return VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "briefcase.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.purple)
                
                Text("Job Offer")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.purple)
                
                Spacer()
                
                if let offer = message.jobOffer {
                    Text("$\(offer.rate)/\(offer.duration.lowercased())")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            if let offer = message.jobOffer {
                // Description
                Text(offer.description)
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                
                // Details
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Text("\(formatDate(offer.startDate)) - \(formatDate(offer.endDate))")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                
                // Action buttons (only show for receiver)
                if !isMe && offer.status == .pending {
                    HStack(spacing: 12) {
                        Button("Decline") {
                            updateOfferStatus(messageId: message.id, status: .declined)
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(15)
                        
                        Button("Accept") {
                            updateOfferStatus(messageId: message.id, status: .accepted)
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .cornerRadius(15)
                    }
                } else if offer.status != .pending {
                    // Status indicator
                    HStack(spacing: 6) {
                        Image(systemName: offer.status == .accepted ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(offer.status == .accepted ? .green : .red)
                        
                        Text(offer.status == .accepted ? "Accepted" : "Declined")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(offer.status == .accepted ? .green : .red)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20, corners: isMe ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight])
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.purple.opacity(0.3), lineWidth: 2)
        )
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
    }

    // MARK: - Messaging Functions
    private func sendMessage() {
        guard !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let message = ChatMessage(
            content: newMessage.trimmingCharacters(in: .whitespacesAndNewlines),
            senderEmail: myEmail,
            type: .text
        )
        
        messages.append(message)
        saveMessages()
        updateChatPreview(with: message.content)
        newMessage = ""
        hideKeyboard()
    }
    
    private func sendJobOffer() {
        guard !offerDescription.isEmpty, !offerRate.isEmpty else { return }
        
        let offer = JobOffer(
            description: offerDescription,
            rate: offerRate,
            duration: offerDuration,
            startDate: offerStartDate,
            endDate: offerEndDate
        )
        
        let message = ChatMessage(
            content: "Job offer sent",
            senderEmail: myEmail,
            type: .jobOffer,
            jobOffer: offer
        )
        
        messages.append(message)
        saveMessages()
        updateChatPreview(with: "📋 Job offer sent")
        
        // Reset form
        offerDescription = ""
        offerRate = ""
        offerDuration = "Weekly"
        offerStartDate = Date()
        offerEndDate = Date().addingTimeInterval(86400 * 7)
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showOfferPanel = false
        }
    }
    
    private func updateOfferStatus(messageId: UUID, status: JobOfferStatus) {
        if let index = messages.firstIndex(where: { $0.id == messageId }) {
            messages[index].jobOffer?.status = status
            saveMessages()
            
            // Send a confirmation message
            let statusMessage = status == .accepted ? "Offer accepted! 🎉" : "Offer declined."
            let confirmationMessage = ChatMessage(
                content: statusMessage,
                senderEmail: myEmail,
                type: .text
            )
            
            messages.append(confirmationMessage)
            saveMessages()
            updateChatPreview(with: statusMessage)
        }
    }

    private func loadMessages() {
        if let saved = UserDefaults.standard.data(forKey: "chat_\(chatId)"),
           let decoded = try? JSONDecoder().decode([ChatMessage].self, from: saved) {
            messages = decoded
        }
    }

    private func saveMessages() {
        if let encoded = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(encoded, forKey: "chat_\(chatId)")
        }
    }
    
    private func updateChatPreview(with content: String) {
        UserDefaults.standard.set(content, forKey: "chatPreview_\(chatId)")
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastMessage_\(chatId)")
        
        // Increment unread count for the other user
        let unreadKey = "unread_\(otherUserEmail)_from_\(myEmail)"
        let currentUnread = UserDefaults.standard.integer(forKey: unreadKey)
        UserDefaults.standard.set(currentUnread + 1, forKey: unreadKey)
    }
    
    private func markMessagesAsRead() {
        // Mark messages from this user as read
        let unreadKey = "unread_\(myEmail)_from_\(otherUserEmail)"
        UserDefaults.standard.set(0, forKey: unreadKey)
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
    
    // MARK: - Helper Functions
    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "now"
        } else if interval < 3600 {
            return "\(Int(interval/60))m"
        } else if interval < 86400 {
            return "\(Int(interval/3600))h"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Chat Message Models
struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let senderEmail: String
    let timestamp: Date
    let type: MessageType
    var jobOffer: JobOffer?
    
    init(content: String, senderEmail: String, type: MessageType, jobOffer: JobOffer? = nil) {
        self.id = UUID()
        self.content = content
        self.senderEmail = senderEmail
        self.timestamp = Date()
        self.type = type
        self.jobOffer = jobOffer
    }
    
    // Equatable conformance
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        return lhs.id == rhs.id
    }
}

enum MessageType: String, Codable {
    case text
    case jobOffer
    case image
}

struct JobOffer: Codable, Equatable {
    let id: UUID
    let description: String
    let rate: String
    let duration: String
    let startDate: Date
    let endDate: Date
    var status: JobOfferStatus
    
    init(description: String, rate: String, duration: String, startDate: Date, endDate: Date) {
        self.id = UUID()
        self.description = description
        self.rate = rate
        self.duration = duration
        self.startDate = startDate
        self.endDate = endDate
        self.status = .pending
    }
    
    // Equatable conformance
    static func == (lhs: JobOffer, rhs: JobOffer) -> Bool {
        return lhs.id == rhs.id
    }
}

enum JobOfferStatus: String, Codable {
    case pending
    case accepted
    case declined
}

// MARK: - Profile Viewer (Read-only)
struct ProfileViewerView: View {
    let profile: UserProfile
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile image
                if let firstImage = profile.imageFileNames.first,
                   let uiImage = FileStorageHelpers.loadImageFromDocuments(filename: firstImage) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 300)
                        .clipped()
                        .cornerRadius(20)
                        .shadow(color: .gray.opacity(0.3), radius: 8, x: 0, y: 4)
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.gray)
                        .padding(.top, 40)
                }
                
                VStack(spacing: 12) {
                    Text("\(profile.name), \(profile.age)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                    
                    Text(profile.description)
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                Spacer()
            }
            .padding()
        }
        .background(Color(red: 0.96, green: 0.95, blue: 0.90).ignoresSafeArea())
    }
}

// MARK: - Extensions
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
    
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        return self.clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = CGFloat.infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
