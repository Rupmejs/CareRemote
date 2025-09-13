import SwiftUI

struct NewView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                // Background same as ContentView and registration pages
                Color(red: 0.96, green: 0.95, blue: 0.90)
                    .ignoresSafeArea()

                VStack(spacing: 40) {
                    Spacer().frame(height: 150)

                    // xCare title with gradient style
                    Text("xCare")
                        .font(.system(size: 50, weight: .bold, design: .rounded))
                        .foregroundStyle(LinearGradient(
                            colors: [Color(red: 0.4, green: 0.8, blue: 1.0), Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)

                    Spacer()

                    // White container card slightly inset from edges
                    VStack(spacing: 25) {
                        // Nannies Button
                        NavigationLink(destination: RegisterNannies()) {
                            Text("Nannies")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.8))
                                .cornerRadius(16)
                                .shadow(color: .gray.opacity(0.3), radius: 6, x: 0, y: 4)
                        }
                        .padding(.horizontal, 15) // <-- inset inside container

                        // Parents Button
                        NavigationLink(destination: RegisterParents()) {
                            Text("Parents")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.8))
                                .cornerRadius(16)
                                .shadow(color: .gray.opacity(0.3), radius: 6, x: 0, y: 4)
                        }
                        .padding(.horizontal, 15) // <-- inset inside container
                    }
                    .padding(.vertical, 30)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(25)
                    .shadow(color: .gray.opacity(0.3), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 20) // <-- moves the whole white box off the edges

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    NewView()
}

