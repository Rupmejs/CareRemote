import SwiftUI

struct NewView: View {
    var body: some View {
        NavigationStack { // Embed everything in NavigationStack
            ZStack {
                // Full-screen beige background
                Color(red: 0.96, green: 0.95, blue: 0.90)
                    .ignoresSafeArea()

                VStack(spacing: 30) {

                    Spacer()
                        .frame(height: 150) // keeps title higher

                    // xCare title in body
                    Text("xCare")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)

                    Spacer() // pushes buttons lower

                    // Nannies button
                    NavigationLink(destination: RegisterNannies()) {
                        Text("Nannies")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }

                    // Parents button
                    NavigationLink(destination: RegisterParents()) {
                        Text("Parents")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }

                    Spacer() // pushes buttons closer to bottom
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationBarTitleDisplayMode(.inline)
            //.navigationTitle("xCare") // <-- Removed the white text at the top
        }
    }
}

#Preview {
    NewView()
}

