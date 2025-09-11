import SwiftUI

struct NewView: View {
    var body: some View {
        ZStack {
            // Full-screen beige background
            Color(red: 0.96, green: 0.95, blue: 0.90)
                .ignoresSafeArea()

            VStack(spacing: 30) {

                Spacer()
                    .frame(height: 150) // keeps title higher

                // xCare title
                Text("xCare")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
                    .padding(.bottom, 0)

                Spacer() // pushes buttons lower

                // SecondView button
                NavigationLink(destination: SecondView()) {
                    Text("Nanny")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }

                // ThirdView button
                NavigationLink(destination: ThirdView()) {
                    Text("Baby")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }

                Spacer() // optional bottom spacer
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("xCare") // title at top of navigation bar
    }
}

#Preview {
    NewView()
}

