import SwiftUI

struct ProfileCard: Identifiable {
    let id = UUID()
    let title: String
    let color: Color
    var description: String
}

struct HomeView: View {
    @State private var cards: [ProfileCard] = [
        ProfileCard(title: "Nanny", color: .blue, description: "Experienced nanny, 5 years with toddlers."),
        ProfileCard(title: "Parent", color: .green, description: "Looking for part-time help.")
    ]

    @State private var dragOffset: CGSize = .zero
    @State private var currentIndex = 0

    @State private var loggedInUserType: String = UserDefaults.standard.string(forKey: "loggedInUserType") ?? "nanny"
    @State private var userProfile: UserProfile?
    @State private var showProfileEditor = false
    @State private var profileIncomplete = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.96, green: 0.95, blue: 0.90).ignoresSafeArea()

                VStack {
                    Text("xCare")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                        .padding(.top, 80)

                    Spacer()

                    if profileIncomplete {
                        Button("Create Profile") {
                            showProfileEditor = true
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                        .padding(.horizontal, 24)

                        Spacer()
                    } else {
                        if currentIndex < cards.count {
                            let card = cards[currentIndex]
                            ZStack {
                                RoundedRectangle(cornerRadius: 28)
                                    .fill(card.color)
                                    .frame(height: 480)
                                    .shadow(radius: 5)

                                VStack(spacing: 20) {
                                    Text(card.title)
                                        .font(.title.bold())
                                        .foregroundColor(.white)
                                    Text(card.description)
                                        .foregroundColor(.black)
                                        .padding()
                                }
                            }
                            .offset(x: dragOffset.width)
                            .rotationEffect(.degrees(Double(dragOffset.width / 20)))
                            .gesture(
                                DragGesture()
                                    .onChanged { dragOffset = $0.translation }
                                    .onEnded { _ in
                                        if dragOffset.width > 120 || dragOffset.width < -120 {
                                            nextCard()
                                        }
                                        dragOffset = .zero
                                    }
                            )
                            .animation(.spring(), value: dragOffset)
                            .padding(.horizontal, 20)
                        } else {
                            Text("No more profiles")
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                }
            }
            .navigationBarBackButtonHidden(true) // ✅ hide back button
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showProfileEditor) {
                ProfileEditorView(userType: loggedInUserType) { saved in
                    // Save profile to UserDefaults
                    if let encoded = try? JSONEncoder().encode(saved) {
                        UserDefaults.standard.set(encoded, forKey: "\(loggedInUserType)_profile")
                    }
                    userProfile = saved
                    profileIncomplete = false
                }
            }
            .onAppear { checkProfile() }
        }
    }

    private func nextCard() {
        currentIndex += 1
        if currentIndex >= cards.count {
            currentIndex = 0
        }
    }

    private func checkProfile() {
        // Load profile
        if let data = UserDefaults.standard.data(forKey: "\(loggedInUserType)_profile"),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            userProfile = decoded
            profileIncomplete = false
        } else {
            profileIncomplete = true
            showProfileEditor = true
        }
    }
}

